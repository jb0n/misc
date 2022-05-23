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
	Port     uint16
	Database string
	SSLMode  string
	Verbose  bool
}

func getConfig() (*dbConfig, error) {
	if len(os.Args) != 2 {
		return nil, fmt.Errorf("usage: %s <.pgpass host substring>", os.Args[0])
	}
	pgpassEntry := os.Args[1]

	cfgs, err := parsePgpass()
	if err != nil {
		return nil, err
	}
	for _, cfg := range cfgs {
		if strings.HasPrefix(cfg.Host, pgpassEntry) {
			fmt.Printf("Using .pgpass data for prefix '%s\n", pgpassEntry)
			return cfg, nil
		}
	}
	return nil, fmt.Errorf("couldn't find entry for '%s' in ~/.pgpass", pgpassEntry)
}

// this function makes a lot of assumptions about how the ~.pgpass file is going to look and what
// entries it'll have specifically, but I think they're safe assumptions
func parsePgpass() ([]*dbConfig, error) {
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
	var cfgs []*dbConfig
	for i, line := range lines {
		cfg := &dbConfig{}
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
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
		cfg.Port = uint16(port)
		cfg.Database = fields[2]
		cfg.User = fields[3]
		cfg.Pass = fields[4]
		cfg.SSLMode = "disable"
		cfg.Verbose = true
		cfgs = append(cfgs, cfg)
	}
	return cfgs, nil
}

func dieOnErr(err error) {
	if err != nil {
		fmt.Println("ERROR: " + err.Error())
		os.Exit(1)
	}
}

func main() {
	if len(os.Args) == 1 {
		cfgs, err := parsePgpass()
		if err != nil {
			dieOnErr(err)
		}
		for _, cfg := range cfgs {
			fmt.Println(cfg.Host)
		}
		return
	}
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
