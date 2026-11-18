"""Gate arithmetic. No Bend process: the fits and the margin formula are pure."""

import contextlib
import io
import json
import unittest
from pathlib import Path

import scale_gate as g

ROOT = Path(__file__).resolve().parent


def _points(pairs):
    return [{"cell": str(x), "x": x, "median": y, "samples": [y], "cv": 0.0} for x, y in pairs]


class FitTests(unittest.TestCase):
    def test_student_t_matches_the_published_table(self):
        self.assertEqual(g.student_t_975(2), 4.302652729911275)
        self.assertEqual(g.student_t_975(40), g.T_NORMAL)

    def test_perfect_quadratic_is_within_an_asymptotic_bound(self):
        fit = g.fit_points(_points([(n, n * n) for n in (46, 92, 184, 368)]))
        self.assertAlmostEqual(fit["slope"], 2.0, places=9)
        self.assertAlmostEqual(fit["r2"], 1.0, places=9)
        config = {"slack": 0.35, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 2.0}
        status, allowed = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "within")
        self.assertAlmostEqual(allowed, 2.35)

    def test_perfect_quadratic_is_worse_than_a_tighter_range(self):
        fit = g.fit_points(_points([(n, float(n * n)) for n in (46, 92, 184, 368)]))
        config = {"slack": 0.35, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 1.0, "max_exponent": 1.35}
        status, allowed = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "worse")
        self.assertAlmostEqual(allowed, 1.35)

    def test_straddle_is_inconclusive(self):
        # Slope 2 with enough noise that the interval crosses 2.1.
        ys = [10.0, 50.0, 90.0, 400.0]
        xs = [46, 92, 184, 368]
        fit = g.fit_points(_points(list(zip(xs, ys))))
        self.assertLess(fit["low"], 2.1)
        self.assertGreater(fit["high"], 2.1)
        config = {"slack": 0.0, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 2.1}
        status, _ = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "inconclusive")

    def test_low_r2_is_inconclusive(self):
        fit = g.fit_points(_points([(10, 1.0), (20, 100.0), (40, 2.0), (80, 90.0)]))
        self.assertLess(fit["r2"], 0.75)
        config = {"slack": 0.35, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 5.0}
        status, _ = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "inconclusive")

    def test_flat_series_under_the_allowed_slope_is_skipped(self):
        fit = g.fit_points(_points([(15, 100.0), (45, 105.0), (91, 110.0), (231, 121.0)]))
        self.assertLess(fit["high"], 1.35)
        self.assertLess(g.growth_ratio(fit["ys"]), 2.0)
        config = {"slack": 0.35, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 1.0, "flat_ok": True}
        status, _ = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "skipped")

    def test_flat_series_above_the_allowed_slope_fails(self):
        # Huge scatter that still ends higher, upper bound over the allowance.
        fit = g.fit_points(_points([(15, 10.0), (45, 10.0), (91, 10.0), (231, 80.0)]))
        config = {"slack": 0.35, "min_r_squared": 0.0, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 0.0, "flat_ok": True, "max_exponent": 0.2}
        status, _ = g.classify_fit(fit, workload, config)
        self.assertNotEqual(status, "skipped")
        self.assertIn(status, ("worse", "inconclusive"))

    def test_cubic_synthetic_is_worse_than_quadratic(self):
        fit = g.fit_points(_points([(n, float(n ** 3)) for n in (46, 92, 184, 368)]))
        self.assertAlmostEqual(fit["slope"], 3.0, places=9)
        config = {"slack": 0.35, "min_r_squared": 0.75, "min_time_ratio": 2.0, "memory_min_ratio": 1.25}
        workload = {"metric": "time", "expected_exponent": 2.0}
        status, _ = g.classify_fit(fit, workload, config)
        self.assertEqual(status, "worse")


class MarginTests(unittest.TestCase):
    def test_published_time_margin_rounds_to_0_521(self):
        # Published example: CV 0.10400740303493287, medians 0.0298496 and 0.0263885.
        cv = 0.10400740303493287
        need = g.margin_need(cv, 0.0298496, 0.0263885)
        self.assertAlmostEqual(need, 0.5200370151746644, places=9)
        self.assertAlmostEqual(0.0298496 / 0.0263885, 1.1311594065596757, places=9)
        self.assertEqual(g.round_up_milli(need), 0.521)

    def test_published_rss_and_managed_margins(self):
        self.assertEqual(g.round_up_milli(0.13263110427830926), 0.133)
        self.assertEqual(g.round_up_milli(0.4511025764755765), 0.452)

    def test_exact_thousandth_is_not_rounded_up(self):
        self.assertEqual(g.round_up_milli(0.500), 0.5)

    def test_margin_uses_the_larger_cv(self):
        a = {"cv": 0.01, "median": 100.0}
        b = {"cv": 0.04, "median": 110.0}
        got = g.margin_from_sweeps(a, b)
        self.assertAlmostEqual(got["cv"], 0.04)
        self.assertGreater(got["margin"], 0.0)


class DecisionTests(unittest.TestCase):
    def test_uniform_slowdown_fails_absolute_and_stays_within(self):
        machine = {"cpu_model": "test", "logical_cpus": 4}
        baseline = {
            "recorded": True,
            "machine": machine,
            "absolute": {"on_different_machine": "skip"},
            "references": {
                "dtlz2-time": {"median": 200.0, "margin": 0.20},
            },
            "fits": {"dtlz2-time": {"slope": 1.6, "endpoint_ratio": 30.0}},
        }
        fast = self._summary("dtlz2-time", "measure", "within", 210.0)
        uniform = self._summary("control-uniform", "uniform", "within", 420.0)
        config = g.load_config()
        fast["absolute"] = g.absolute_status(
            fast["reference"],
            {"id": "dtlz2-time", "role": "measure", "metric": "time"},
            baseline,
            machine,
        )
        uniform["absolute"] = g.absolute_status(
            uniform["reference"],
            {"id": "control-uniform", "role": "uniform", "metric": "time", "baseline_of": "dtlz2-time"},
            baseline,
            machine,
        )
        self.assertEqual(fast["absolute"], "pass")
        self.assertEqual(uniform["absolute"], "fail")
        self.assertTrue(g.uniform_caught(uniform))
        code, problems = g.decide([fast, uniform])
        self.assertEqual(code, 0, problems)
        # A missing baseline does not count the uniform control as caught.
        bare = dict(uniform)
        bare["absolute"] = "skipped-no-baseline"
        code, _ = g.decide([fast, bare])
        self.assertEqual(code, 2)
        self.assertTrue(config["workloads"])

    def test_quadratic_time_control_is_caught_by_the_endpoint_ratio(self):
        caught = {
            "id": "control-quadratic",
            "role": "control",
            "metric": "time",
            "catch": "endpoint-ratio",
            "fit_status": "within",
            "ratio_check": "fail",
        }
        missed = dict(caught)
        missed["ratio_check"] = "pass"
        bare = dict(caught)
        bare["ratio_check"] = "skipped-no-baseline"
        self.assertTrue(g.control_caught(caught))
        self.assertEqual(g.decide([caught])[0], 0)
        self.assertEqual(g.decide([missed])[0], 1)
        self.assertEqual(g.decide([bare])[0], 2)

    def test_committed_runner_margins_match_the_formula(self):
        base = json.loads((ROOT / "baseline.json").read_text(encoding="utf-8"))
        self.assertTrue(base["recorded"])
        self.assertEqual(base["machine"]["cpu_model"], "AMD EPYC 7763 64-Core Processor")
        self.assertEqual(base["machine"]["logical_cpus"], 4)
        for key in ("dtlz2-time", "dtlz2-wall", "dtlz2-r", "dtlz2-rss", "alloc-linear"):
            ref = base["references"][key]
            need = g.margin_need(max(ref["cv"], ref["other_cv"]), ref["other_median"], ref["median"])
            self.assertEqual(ref["margin"], g.round_up_milli(need), key)
            self.assertAlmostEqual(ref["margin_need"], need, places=12, msg=key)
        time = base["references"]["dtlz2-time"]
        need = g.margin_need(time["endpoint_cv"], time["other_endpoint_ratio"], time["endpoint_ratio"])
        self.assertEqual(time["ratio_margin"], g.round_up_milli(need))
        self.assertAlmostEqual(time["ratio_ceiling"], time["endpoint_ratio"] * (1.0 + time["ratio_margin"]))
        for key in ("dtlz2-time", "dtlz2-wall", "dtlz2-r"):
            for cpu, row in base["references"][key]["by_cpu"].items():
                if "other_median" in row:
                    cv = max(row["cv"], row["other_cv"])
                    need = g.margin_need(cv, row["other_median"], row["median"])
                else:
                    need = 5.0 * row["cv"]
                self.assertEqual(row["margin"], g.round_up_milli(need), f"{key} {cpu}")
                self.assertAlmostEqual(row["margin_need"], need, places=12, msg=f"{key} {cpu}")
        for key in ("dtlz2-rss", "alloc-linear"):
            ref = base["references"][key]
            cross = ref["cross_run"]
            xs = cross["medians"]
            need = g.margin_need(g.coefficient_of_variation(xs), min(xs), max(xs))
            self.assertAlmostEqual(cross["margin_need"], need, places=12, msg=key)
            self.assertGreaterEqual(ref["margin"], cross["margin"])
        # The N² loop's measured ratio has to clear that ceiling, and the two
        # algorithm sweeps have to sit under it.
        self.assertGreater(63.1875, time["ratio_ceiling"])
        self.assertLess(time["endpoint_ratio"], time["ratio_ceiling"])
        self.assertLess(time["other_endpoint_ratio"], time["ratio_ceiling"])

    def test_uniform_skipped_machine_is_not_caught(self):
        skipped = {
            "id": "control-uniform",
            "role": "uniform",
            "metric": "time",
            "fit_status": "within",
            "absolute": "skipped-machine",
            "reference": {"cpu": "unknown"},
        }
        with contextlib.redirect_stderr(io.StringIO()) as err:
            code, problems = g.decide([skipped])
        self.assertEqual(code, 1)
        self.assertIn("control-uniform:absolute:not-fail", problems)
        self.assertIn("::warning", err.getvalue())
        self.assertFalse(g.uniform_caught(skipped))

    def test_control_must_be_worse_not_merely_failing(self):
        caught = {"id": "control-quadratic", "role": "control", "metric": "time", "fit_status": "worse"}
        missed = {"id": "control-quadratic", "role": "control", "metric": "time", "fit_status": "within"}
        straddling = {"id": "control-quadratic", "role": "control", "metric": "time", "fit_status": "inconclusive"}
        self.assertEqual(g.decide([caught])[0], 0)
        self.assertEqual(g.decide([missed])[0], 1)
        self.assertEqual(g.decide([straddling])[0], 1)

    def test_unknown_cpu_fails_and_a_recorded_cpu_runs_the_check(self):
        baseline = {
            "recorded": True,
            "machine": {"cpu_model": "A", "logical_cpus": 4},
            "absolute": {"on_different_machine": "per-cpu"},
            "references": {
                "dtlz2-time": {
                    "median": 200.0,
                    "margin": 0.043,
                    "by_cpu": {
                        "A": {"logical_cpus": 4, "median": 200.0, "margin": 0.043},
                        "B": {"logical_cpus": 4, "median": 221.0, "margin": 0.077},
                    },
                },
                "dtlz2-rss": {"median": 15000.0, "margin": 0.109},
            },
        }
        unknown = {}
        status = g.absolute_status(
            unknown,
            {"id": "dtlz2-time", "role": "measure", "metric": "time"},
            baseline,
            {"cpu_model": "C", "logical_cpus": 4},
        )
        self.assertEqual(status, "skipped-machine")
        summary = {
            "id": "dtlz2-time",
            "role": "measure",
            "metric": "time",
            "fit_status": "within",
            "legacy": [],
            "absolute": status,
            "reference": unknown,
        }
        with contextlib.redirect_stderr(io.StringIO()) as err:
            code, problems = g.decide([summary])
        self.assertEqual(code, 1, problems)
        self.assertIn("dtlz2-time:absolute:skipped-machine", problems)
        self.assertIn("::warning", err.getvalue())
        self.assertFalse(g.measure_ok(summary))
        known = {"median": 221.0}
        status = g.absolute_status(
            known,
            {"id": "dtlz2-time", "role": "measure", "metric": "time"},
            baseline,
            {"cpu_model": "B", "logical_cpus": 4},
        )
        self.assertEqual(status, "pass")
        self.assertAlmostEqual(known["limit"], 221.0 * 1.077)
        slow = {"median": 444.0}
        status = g.absolute_status(
            slow,
            {"id": "control-uniform", "role": "uniform", "metric": "time", "baseline_of": "dtlz2-time"},
            baseline,
            {"cpu_model": "B", "logical_cpus": 4},
        )
        self.assertEqual(status, "fail")
        rss = {"median": 15200.0}
        status = g.absolute_status(
            rss,
            {"id": "dtlz2-rss", "role": "measure", "metric": "rss"},
            baseline,
            {"cpu_model": "C", "logical_cpus": 4},
        )
        self.assertEqual(status, "pass")

    def test_legacy_ceiling_still_fails_a_steep_point_estimate(self):
        fit = {"slope": 2.6, "ys": [1.0, 2.0, 4.0, 8.0]}
        workload = {"metric": "time", "legacy_ceiling": g.LEGACY_CEILINGS["time_vs_n"]}
        self.assertIn("ceiling", g.legacy_point_failures(fit, workload, None))
        fit["slope"] = 2.4
        self.assertEqual(g.legacy_point_failures(fit, workload, None), [])

    def test_legacy_exponent_drift_is_kept(self):
        fit = {"slope": 2.1, "ys": [10.0, 80.0]}
        base = {"slope": 1.5, "endpoint_ratio": 8.0}
        workload = {"metric": "time"}
        self.assertIn("exponent-drift", g.legacy_point_failures(fit, workload, base))

    def test_span_requires_eight_times(self):
        config = {"min_n_span": 8.0}
        self.assertTrue(g.span_ok([46, 368], config))
        self.assertFalse(g.span_ok([46, 184], config))

    def test_committed_ceilings_are_the_old_lock(self):
        self.assertEqual(g.LEGACY_CEILINGS["time_vs_n"], 2.5)
        self.assertEqual(g.LEGACY_CEILINGS["time_vs_r"], 1.5)
        self.assertEqual(g.LEGACY_CEILINGS["rss_vs_n"], 1.0)
        self.assertEqual(g.LEGACY_EXPONENT_MARGIN, 0.40)
        self.assertEqual(g.LEGACY_RATIO_MARGIN, 1.75)
        config = json.loads((ROOT / "gate.config.json").read_text(encoding="utf-8"))
        by_id = {w["id"]: w for w in config["workloads"]}
        self.assertEqual(by_id["dtlz2-time"]["legacy_ceiling"], 2.5)
        self.assertEqual(by_id["dtlz2-r"]["legacy_ceiling"], 1.5)
        self.assertEqual(by_id["dtlz2-wall"]["legacy_ceiling"], 2.5)
        self.assertEqual(by_id["dtlz2-time"]["max_exponent"], 2.19)
        self.assertGreater(by_id["dtlz2-time"]["max_exponent"], 1.9895696937018328)
        self.assertEqual(by_id["control-quadratic"]["catch"], "endpoint-ratio")
        self.assertEqual(by_id["control-uniform"]["baseline_of"], "dtlz2-time")
        self.assertNotIn("a400", by_id["control-alloc"]["cells"])
        self.assertGreaterEqual(6400 / 800, config["min_n_span"])
        self.assertGreaterEqual(368 / 46, config["min_n_span"])
        self.assertEqual(config["absolute"]["on_different_machine"], "per-cpu")
        self.assertEqual(config["min_r_squared"], 0.75)
        self.assertEqual(config["slack"], 0.35)
        self.assertEqual(config["measured_runs"], 5)
        self.assertEqual(config["warmup_runs"], 1)

    def _summary(self, name, role, status, median):
        return {
            "id": name,
            "role": role,
            "metric": "time",
            "fit_status": status,
            "legacy": [],
            "reference": {"cell": "m3p12n92", "median": median, "samples": [median], "cv": 0.0},
        }


class OlsSeTests(unittest.TestCase):
    def test_zero_residual_has_zero_width(self):
        fit = g.ols([1, 2, 4, 8], [1, 2, 4, 8])
        self.assertAlmostEqual(fit["slope"], 1.0, places=9)
        self.assertAlmostEqual(fit["low"], fit["high"], places=9)

    def test_log_of_non_positive_is_rejected(self):
        with self.assertRaises(ValueError):
            g.ols([1, 2, 4], [1, 0, 4])
        with self.assertRaises(ValueError):
            g.median([])


if __name__ == "__main__":
    unittest.main()
