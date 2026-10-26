package main

import (
	"errors"
	"io/fs"
	"math/big"
	"path/filepath"
	"testing"
)

func TestLoadCitiesMissingFileReturnsError(t *testing.T) {
	path := filepath.Join(t.TempDir(), "missing.json")

	cities, err := loadCities(path)
	if err == nil {
		t.Fatal("expected error for missing file, got nil")
	}
	if !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("expected wrapped fs.ErrNotExist, got %v", err)
	}
	if cities != nil {
		t.Errorf("expected nil cities, got %v", cities)
	}
}

func TestBuildAuthInvalidKeyReturnsError(t *testing.T) {
	auth, err := buildAuth("not-a-hex-key", big.NewInt(42161))
	if err == nil {
		t.Fatal("expected error for invalid private key, got nil")
	}
	if auth != nil {
		t.Errorf("expected nil auth, got %v", auth)
	}
}
