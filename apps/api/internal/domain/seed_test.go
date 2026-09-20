package domain_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

func findRepoRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "pnpm-workspace.yaml")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	// Fallback to relative path
	return filepath.Join("..", "..", "..", ".."), nil
}

func TestSeedScriptValidity(t *testing.T) {
	root, err := findRepoRoot()
	if err != nil {
		t.Fatalf("failed to find repo root: %v", err)
	}

	seedPath := filepath.Join(root, "scripts", "seed_dev.sql")
	content, err := os.ReadFile(seedPath)
	if err != nil {
		t.Fatalf("failed to read seed_dev.sql at %s: %v", seedPath, err)
	}
	sqlText := string(content)

	// Check clusters
	requiredClusters := []string{"sukamaju-001", "harapan-002"}
	for _, cluster := range requiredClusters {
		if !strings.Contains(sqlText, cluster) {
			t.Errorf("expected seed SQL to contain cluster %s", cluster)
		}
	}

	// Check roles
	requiredRoles := []string{"superadmin", "backoffice_admin", "merchant", "wholesaler", "courier", "consumer"}
	for _, role := range requiredRoles {
		if !strings.Contains(sqlText, role) {
			t.Errorf("expected seed SQL to contain role %s", role)
		}
	}

	// Verify bcrypt hash matches Password123!
	expectedHash := "$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS"
	if !strings.Contains(sqlText, expectedHash) {
		t.Errorf("expected seed SQL to contain the exact bcrypt hash for Password123!")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(expectedHash), []byte("Password123!")); err != nil {
		t.Errorf("expected seed hash to match 'Password123!', got: %v", err)
	}

	// Verify idempotency keyword
	if !strings.Contains(sqlText, "ON CONFLICT") {
		t.Errorf("expected seed script to be idempotent using ON CONFLICT")
	}
}

func TestSeedRunnerScript(t *testing.T) {
	root, err := findRepoRoot()
	if err != nil {
		t.Fatalf("failed to find repo root: %v", err)
	}

	scriptPath := filepath.Join(root, "scripts", "seed.sh")
	info, err := os.Stat(scriptPath)
	if err != nil {
		t.Fatalf("failed to find seed.sh at %s: %v", scriptPath, err)
	}

	// Verify executable permission
	if info.Mode()&0111 == 0 {
		t.Errorf("expected seed.sh to be executable")
	}
}
