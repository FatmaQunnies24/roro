"""
Small training example with pure Python (no external libs).
"""

from training_data import generate_samples


def sigmoid(x: float) -> float:
    return 1.0 / (1.0 + (2.718281828 ** (-x)))


def train_logistic_regression(epochs: int = 300, lr: float = 0.0009) -> tuple[list[float], float]:
    samples = generate_samples()

    # weights: shots, possession, pass_accuracy, high_intensity_runs
    w = [0.0, 0.0, 0.0, 0.0]
    b = 0.0

    for _ in range(epochs):
        for s in samples:
            x = [s.shots_on_target, s.possession, s.pass_accuracy, s.high_intensity_runs]
            y = s.label_win

            z = (w[0] * x[0]) + (w[1] * x[1]) + (w[2] * x[2]) + (w[3] * x[3]) + b
            y_hat = sigmoid(z)
            error = y_hat - y

            w[0] -= lr * error * x[0]
            w[1] -= lr * error * x[1]
            w[2] -= lr * error * x[2]
            w[3] -= lr * error * x[3]
            b -= lr * error

    return w, b


if __name__ == "__main__":
    weights, bias = train_logistic_regression()
    print("Trained weights:", [round(v, 4) for v in weights])
    print("Trained bias:", round(bias, 4))
