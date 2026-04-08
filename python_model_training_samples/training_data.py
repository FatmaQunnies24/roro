"""
Synthetic football dataset for training practice.
"""

from dataclasses import dataclass
from random import Random


@dataclass
class MatchSample:
    shots_on_target: int
    possession: int
    pass_accuracy: int
    high_intensity_runs: int
    label_win: int


def generate_samples(size: int = 200, seed: int = 7) -> list[MatchSample]:
    rng = Random(seed)
    samples: list[MatchSample] = []

    for _ in range(size):
        shots = rng.randint(1, 12)
        possession = rng.randint(35, 70)
        pass_accuracy = rng.randint(65, 95)
        runs = rng.randint(40, 140)

        score = (shots * 0.35) + (possession * 0.02) + (pass_accuracy * 0.015) + (runs * 0.004)
        noisy_score = score + rng.uniform(-1.2, 1.2)
        label_win = 1 if noisy_score >= 5.6 else 0

        samples.append(
            MatchSample(
                shots_on_target=shots,
                possession=possession,
                pass_accuracy=pass_accuracy,
                high_intensity_runs=runs,
                label_win=label_win,
            )
        )

    return samples
