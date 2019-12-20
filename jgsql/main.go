package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
)

type dbConfig struct {
	Host     string
	User     string
	Pass     string
	Port     int
	Database string
	SSLMode  string
	Verbose  bool
}

func getConfig() (*dbConfig, error) {
	if len(os.Args) != 2 {
		return nil, fmt.Errorf("usage: %s <.pgpass host substring>", os.Args[0])
	}
	pgpassEntry := os.Args[1]

	cfg, err := parsePgpass(pgpassEntry)
	if err != nil {
		return nil, err
	}
	fmt.Printf("Using .pgpass data for prefix '%s\n", pgpassEntry)
	return cfg, nil
}

// this function makes a lot of assumptions about how the ~.pgpass file is going to look and what
// entries it'll have specifically, but I think they're safe assumptions
func parsePgpass(entryPfx string) (*dbConfig, error) {
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}
	fn := filepath.Join(usr.HomeDir, filepath.Clean(".pgpass"))
	b, err := ioutil.ReadFile(filepath.Clean(fn))
	if err != nil {
		err = fmt.Errorf("error reading '%s'. err=%s", fn, err)
		return nil, err
	}
	lines := strings.Split(string(b), "\n")
	var cfg *dbConfig
	for i, line := range lines {
		if strings.HasPrefix(line, entryPfx) { // assumes first match is good enough.
			cfg = &dbConfig{}
			fields := strings.Split(line, ":")
			if len(fields) != 5 {
				return nil, fmt.Errorf("the line #%d had only %d fields, expected 5", i+1,
					len(fields))
			}
			cfg.Host = fields[0]
			port, parseErr := strconv.ParseInt(fields[1], 10, 16)
			if parseErr != nil {
				return nil, fmt.Errorf("bad port '%s'", fields[1])
			}
			cfg.Port = int(port)
			cfg.Database = fields[2]
			cfg.User = fields[3]
			cfg.Pass = fields[4]
			cfg.SSLMode = "disable"
			cfg.Verbose = true
			return cfg, nil
		}
	}
	return nil, fmt.Errorf("couldn't find entry for '%s' in %s", entryPfx, fn)
}

func dieOnErr(err error) {
	if err != nil {
		fmt.Println("ERROR: " + err.Error())
		os.Exit(1)
	}
}

func main() {
	cfg, err := getConfig()
	dieOnErr(err)
	fmt.Printf("Connecting to %s as %s\n", cfg.Host, cfg.User)
	psql, err := exec.LookPath("psql")
	dieOnErr(err)
	env := os.Environ()
	args := []string{"psql",
		"-h", cfg.Host,
		"-U", cfg.User,
		"-d", cfg.Database}
	err = syscall.Exec(psql, args, env) // nolint
	dieOnErr(err)
}
