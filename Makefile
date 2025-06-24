fmt_check:
	stylua --check lua/ --config-path=.stylua.toml

fmt:
	stylua lua/ --config-path=.stylua.toml

lint:
	luacheck lua/ --globals vim

test:
	nvim --headless --noplugin -u scripts/tests/minimal.vim -c "PlenaryBustedDirectory lua/nuggets/ { minimal_init = 'scripts/tests/minimal.vim' }"

pr-ready: lua_test lua_fmt lua_lint
