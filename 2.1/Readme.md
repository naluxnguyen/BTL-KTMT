# TASK 2.1 - 3 hàm computeAutocorrelation, computeCrosscorrelation, và createToeplitzMatrix

```c++
// Tính autocorrelation của signal
void computeAutocorrelation(double signal[MAX_SIZE], double autocorr[MAX_SIZE], int N) {
    for (int lag = 0; lag < N; ++lag) {
        double s = 0.0;
        for (int n = 0; n < N - lag; ++n) s += signal[n] * signal[n + lag];
        autocorr[lag] = s;
    }
}

void computeCrosscorrelation(double desired[MAX_SIZE], double input[MAX_SIZE], double crosscorr[MAX_SIZE], int N) {
    for (int lag = 0; lag < N; ++lag) {
        double s = 0.0;
        for (int n = 0; n < N - lag; ++n) s += desired[n + lag] * input[n];
        crosscorr[lag] = s;
    }
}

void createToeplitzMatrix(double autocorr[MAX_SIZE], double R[MAX_SIZE][MAX_SIZE], int N) {
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j)
            R[i][j] = autocorr[abs(i - j)];
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
6.7 3.75 7.045 3.5 7.045 3.5 3.5 7.045 
```

### Chạy với data1 `Bài toán Bộ lọc Wiener với d = [1.5, 2.8, 3.2], x = [1.2, 2.5, 3.0], M = 3` (trong latex)

```sh
# .include "data1.asm"
.include "data2.asm"
```

```sh


# result
Data 2: 
6.1333337 3.7866669 1.2800001 5.5633335 3.5 1.2 5.5633335 3.5 1.2 3.5 5.5633335 3.5 1.2 3.5 5.5633335
```