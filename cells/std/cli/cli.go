package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"text/tabwriter"

	"github.com/oriser/regroup"

	"github.com/rsteube/carapace"
	"github.com/spf13/cobra"

	"github.com/divnix/std/data"
)

type Spec struct {
	Cell   string `regroup:"cell,required"`
	Block  string `regroup:"block,required"`
	Target string `regroup:"target,required"`
	Action string `regroup:"action,required"`
}

var re = regroup.MustCompile(`^//(?P<cell>[^/]+)/(?P<block>[^/]+)/(?P<target>[^:]+):(?P<action>.+)`)

var rootCmd = &cobra.Command{
	Use:                   "std //[cell]/[block]/[target]:[action] [args...]",
	DisableFlagsInUseLine: true,
	Version:               fmt.Sprintf("%s (%s)", buildVersion, buildCommit),
	Short:                 "std is the CLI / TUI companion for Standard",
	Long: `std is the CLI / TUI companion for Standard.

- Invoke without any arguments to start the TUI.
- Invoke with a target spec and action to run a known target's action directly.`,
	Args: func(cmd *cobra.Command, args []string) error {
		s := &Spec{}
		if err := re.MatchToTarget(args[0], s); err != nil {
			return fmt.Errorf("invalid argument format: %s", args[0])
		}
		return nil
	},
	Run: func(cmd *cobra.Command, args []string) {
		s := &Spec{}
		if err := re.MatchToTarget(args[0], s); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		nix, nixargs, err := GetActionEvalCmdArgs(s.Cell, s.Block, s.Target, s.Action)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		// fmt.Printf("%+v\n", append([]string{nix}, nixargs...))
		// fmt.Printf("%+v\n", args)
		if err = bashExecve(append([]string{nix}, nixargs...), args[1:]); err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

	},
}
var reCacheCmd = &cobra.Command{
	Use:   "re-cache",
	Short: "Refresh the CLI cache.",
	Long: `Refresh the CLI cache.
Use this command to cold-start or refresh the CLI cache.
The TUI does this automatically, but the command completion needs manual initialization of the CLI cache.`,
	Args: cobra.NoArgs,
	Run: func(cmd *cobra.Command, args []string) {
		c, key, loadCmd, buf, err := LoadFlakeCmd()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		loadCmd.Run()
		c.PutBytes(*key, buf.Bytes())
		os.Exit(0)
	},
}
var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List available targets.",
	Long: `List available targets.
Shows a list of all available targets. Can be used as an alternative to the TUI.
Also loads the CLI cache, if no cache is found. Reads the cache, otherwise.`,
	Args: cobra.NoArgs,
	Run: func(cmd *cobra.Command, args []string) {
		cache, key, loadCmd, buf, err := LoadFlakeCmd()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		cached, _, err := cache.GetBytes(*key)
		var root *data.Root
		if err == nil {
			root, _ = LoadJson(bytes.NewReader(cached))
		} else {
			loadCmd.Run()
			bufA := &bytes.Buffer{}
			r := io.TeeReader(buf, bufA)
			root, _ = LoadJson(r)
			cache.PutBytes(*key, bufA.Bytes())
		}
		w := tabwriter.NewWriter(os.Stdout, 5, 2, 4, ' ', 0)
		for _, c := range root.Cells {
			for _, o := range c.Blocks {
				for _, t := range o.Targets {
					for _, a := range t.Actions {
						fmt.Fprintln(w, fmt.Sprintf("//%s/%s/%s:%s\t--\t%s:  %s", c.Cell, o.Block, t.Target, a.Name, t.Description, a.Descr))
					}
				}
			}
		}
		w.Flush()
		os.Exit(0)
	},
}

func ExecuteCli() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(reCacheCmd)
	rootCmd.AddCommand(listCmd)
	carapace.Gen(rootCmd).Standalone()
	// completes: '//cell/block/target:action'
	carapace.Gen(rootCmd).PositionalCompletion(
		carapace.ActionCallback(func(c carapace.Context) carapace.Action {
			cache, key, _, _, err := LoadFlakeCmd()
			if err != nil {
				return carapace.ActionMessage(fmt.Sprintf("%v\n", err))
			}
			cached, _, err := cache.GetBytes(*key)
			var root *data.Root
			if err == nil {
				root, err = LoadJson(bytes.NewReader(cached))
				if err != nil {
					return carapace.ActionMessage(fmt.Sprintf("%v\n", err))
				}
			} else {
				return carapace.ActionMessage(fmt.Sprint("No completion cache: please initialize by running 'std re-cache'."))
			}
			var values = []string{}
			for ci, c := range root.Cells {
				for oi, o := range c.Blocks {
					for ti, t := range o.Targets {
						for ai, a := range t.Actions {
							values = append(
								values,
								root.ActionArg(ci, oi, ti, ai),
								fmt.Sprintf("%s: %s", a.Name, t.Description),
							)
						}
					}
				}
			}
			return carapace.ActionValuesDescribed(
				values...,
			).Invoke(c).ToMultiPartsA("/", ":")
		}),
	)
}