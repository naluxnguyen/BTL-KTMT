# Task 2.2 - 2 hàm solveLinearSystem, applyWienerFilter

```c++
// Giải hệ phương trình tuyến tính bằng Gauss elimination
void solveLinearSystem(double A[MAX_SIZE][MAX_SIZE], double b[MAX_SIZE], double x[MAX_SIZE], int N) {
    vector<vector<double>> M(N, vector<double>(N+1));
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) M[i][j] = A[i][j];
        M[i][N] = b[i];
    }

    for (int col = 0; col < N; ++col) {
        int piv = col;
        double maxv = fabs(M[col][col]);
        for (int r = col+1; r < N; ++r) {
            if (fabs(M[r][col]) > maxv) { maxv = fabs(M[r][col]); piv = r; }
        }
        if (piv != col) swap(M[piv], M[col]);

        if (fabs(M[col][col]) < 1e-12) {
            M[col][col] = 1e-12;
        }

        for (int r = col+1; r < N; ++r) {
            double factor = M[r][col] / M[col][col];
            for (int c = col; c <= N; ++c) M[r][c] -= factor * M[col][c];
        }
    }

    vector<double> sol(N, 0.0);
    for (int i = N-1; i >= 0; --i) {
        double s = M[i][N];
        for (int j = i+1; j < N; ++j) s -= M[i][j] * sol[j];
        sol[i] = s / M[i][i];
    }
    for (int i = 0; i < N; ++i) x[i] = sol[i];
}

void computeWienerCoefficients(double desired[MAX_SIZE], double input[MAX_SIZE], int N, double coefficients[MAX_SIZE]) {
    double autocorr[MAX_SIZE];
    double crosscorr[MAX_SIZE];
    double R[MAX_SIZE][MAX_SIZE];

    computeAutocorrelation(input, autocorr, N);
    computeCrosscorrelation(desired, input, crosscorr, N);
    createToeplitzMatrix(autocorr, R, N);
    solveLinearSystem(R, crosscorr, coefficients, N);
}
```

## Run code

### Chạy với data1 `Bài toán Bộ lọc Wiener với d = [2.0, 3.0], x = [2.5, 2.8]` (trong latex)

```sh
.include "data1.asm"
# .include "data2.asm"
```

```sh


# result
Data 1: 
0.9115744 0.07941656 2.2789361 2.7509499
```

### Chạy với data1 `Bài toán Bộ lọc Wiener với d = [1.5, 2.8, 3.2], x = [1.2, 2.5, 3.0], M = 3` (trong latex)

```sh
# .include "data1.asm"
.include "data2.asm"
```

```sh


# result
Data 2: 
1.1174561 -0.025610173 0.005156662 1.3409474 2.762908 3.2945309
```