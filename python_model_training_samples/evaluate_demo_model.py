"""
Evaluate the small demo model on fresh synthetic samples.
"""

from training_data import generate_samples
from train_demo_model import sigmoid, train_logistic_regression


def evaluate(size: int = 80) -> float:
    w, b = train_logistic_regression()
    test_samples = generate_samples(size=size, seed=99)

    correct = 0
    for s in test_samples:
        z = (
            w[0] * s.shots_on_target
            + w[1] * s.possession
            + w[2] * s.pass_accuracy
            + w[3] * s.high_intensity_runs
            + b
        )
        pred = 1 if sigmoid(z) >= 0.5 else 0
        if pred == s.label_win:
            correct += 1

    return correct / len(test_samples)


if __name__ == "__main__":
    acc = evaluate()
    print(f"Demo accuracy: {acc:.2%}")
