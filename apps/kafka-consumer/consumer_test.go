package consumer

import "testing"

func TestAdd(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{name: "zeros", a: 0, b: 0, expected: 0},
		{name: "positives", a: 2, b: 3, expected: 5},
		{name: "negatives", a: -1, b: -2, expected: -3},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Add(tt.a, tt.b); got != tt.expected {
				t.Fatalf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.expected)
			}
		})
	}
}
