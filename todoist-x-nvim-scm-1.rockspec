rockspec_format = "3.0"
package = "todoist-x-nvim"
version = "scm-1"
source = {
	url = "git+https://github.com/danjvarela/todoist-x-nvim",
}
dependencies = {
	"plenary.nvim",
}
test_dependencies = {
	"nlua",
}
build = {
	type = "builtin",
	copy_directories = {
		"plugin",
		"doc",
	},
}
