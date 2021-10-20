// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module os


// file_ext will return the part after the last occurence of `.` in `path`.
// The `.` is included.
pub fn file_ext(path string) string {
	pos := path.last_index('.') or { return '' }
	return path[pos..]
}

// dir returns all but the last element of path, typically the path's directory.
// After dropping the final element, trailing slashes are removed.
// If the path is empty, dir returns ".". If the path consists entirely of separators,
// dir returns a single separator.
// The returned path does not end in a separator unless it is the root directory.
pub fn dir (opath string) string {
	if opath == '' {
		return '.'
	}
	path := opath.replace_each(['/', path_separator, r'\', path_separator])
	pos := path.last_index(path_separator) or { return '.' }
	if pos == 0 && path_separator == '/' {
		return '/'
	}
	return path[..pos]
}

// base returns the last element of path.
// Trailing path separators are removed before extracting the last element.
// If the path is empty, base returns ".". If the path consists entirely of separators, base returns a
// single separator.
pub fn base(opath string) string {
	if opath == '' {
		return '.'
	}
	path := opath.replace_each(['/', path_separator, r'\', path_separator])
	if path == path_separator {
		return path_separator
	}
	if path.ends_with(path_separator) {
		path2 := path[..path.len - 1]
		pos := path2.last_index(path_separator) or { return path2.clone() }
		return path2[pos + 1..]
	}
	pos := path.last_index(path_separator) or { return path.clone() }
	return path[pos + 1..]
}

// file_name will return all characters found after the last occurence of `path_separator`.
// file extension is included.
pub fn file_name(opath string) string {
	path := opath.replace_each(['/', path_separator, r'\', path_separator])
	return path.all_after_last(path_separator)
}

// input_opt returns a one-line string from stdin, after printing a prompt.
// In the event of error (end of input), it returns `none`.
pub fn input_opt(prompt string) ?string {
	print(prompt)
	flush()
	res := get_raw_line()
	if res.len > 0 {
		return res.trim_right('\r\n')
	}
	return none
}

// input returns a one-line string from stdin, after printing a prompt.
// In the event of error (end of input), it returns '<EOF>'.
pub fn input(prompt string) string {
	res := input_opt(prompt) or { return '<EOF>' }
	return res
}

// get_line returns a one-line string from stdin
pub fn get_line() string {
	str := get_raw_line()
	$if windows {
		return str.trim_right('\r\n')
	}
	return str.trim_right('\n')
}

// get_lines returns an array of strings read from from stdin.
// reading is stopped when an empty line is read.
pub fn get_lines() []string {
	mut line := ''
	mut inputstr := []string{}
	for {
		line = get_line()
		if line.len <= 0 {
			break
		}
		line = line.trim_space()
		inputstr << line
	}
	return inputstr
}

// get_lines_joined returns a string of the values read from from stdin.
// reading is stopped when an empty line is read.
pub fn get_lines_joined() string {
	mut line := ''
	mut inputstr := ''
	for {
		line = get_line()
		if line.len <= 0 {
			break
		}
		line = line.trim_space()
		inputstr += line
	}
	return inputstr
}

// get_raw_lines_joined reads *all* input lines from stdin.
// It returns them as one large string. NB: unlike os.get_lines_joined,
// empty lines (that contain only `\r\n` or `\n`), will be present in
// the output.
// Reading is stopped, only on EOF of stdin.
pub fn get_raw_lines_joined() string {
	mut line := ''
	mut lines := []string{}
	for {
		line = get_raw_line()
		if line.len <= 0 {
			break
		}
		lines << line
	}
	res := lines.join('')
	return res
}

// user_os returns current user operating system name.
pub fn user_os() string {
	$if linux {
		return 'linux'
	}
	$if macos {
		return 'macos'
	}
	$if windows {
		return 'windows'
	}
	$if freebsd {
		return 'freebsd'
	}
	$if openbsd {
		return 'openbsd'
	}
	$if netbsd {
		return 'netbsd'
	}
	$if dragonfly {
		return 'dragonfly'
	}
	$if android {
		return 'android'
	}
	$if solaris {
		return 'solaris'
	}
	$if haiku {
		return 'haiku'
	}
	$if serenity {
		return 'serenity'
	}
	$if vinix {
		return 'vinix'
	}
	return 'unknown'
}

// home_dir returns path to the user's home directory.
pub fn home_dir() string {
	$if windows {
		return getenv('USERPROFILE')
	} $else {
		// println('home_dir() call')
		// res:= os.getenv('HOME')
		// println('res="$res"')
		return getenv('HOME')
	}
}

// expand_tilde_to_home expands the character `~` in `path` to the user's home directory.
// See also `home_dir()`.
pub fn expand_tilde_to_home(path string) string {
	if path == '~' {
		return home_dir().trim_right(path_separator)
	}
	if path.starts_with('~' + path_separator) {
		return path.replace_once('~' + path_separator, home_dir().trim_right(path_separator) +
			path_separator)
	}
	return path
}

// write_file writes `text` data to a file in `path`.
pub fn write_file(path string, text string) ? {
	mut f := create(path) ?
	unsafe { f.write_full_buffer(text.str, usize(text.len)) ? }
	f.close()
}

// executable_fallback is used when there is not a more platform specific and accurate implementation.
// It relies on path manipulation of os.args[0] and os.wd_at_startup, so it may not work properly in
// all cases, but it should be better, than just using os.args[0] directly.
fn executable_fallback() string {
	if args.len == 0 {
		// we are early in the bootstrap, os.args has not been initialized yet :-|
		return ''
	}
	mut exepath := args[0]
	$if windows {
		if !exepath.contains('.exe') {
			exepath += '.exe'
		}
	}
	if !is_abs_path(exepath) {
		rexepath := exepath.replace_each(['/', path_separator, r'\', path_separator])
		if rexepath.contains(path_separator) {
			exepath = join_path(os.wd_at_startup, exepath)
		} else {
			// no choice but to try to walk the PATH folders :-| ...
			foundpath := find_abs_path_of_executable(exepath) or { '' }
			if foundpath.len > 0 {
				exepath = foundpath
			}
		}
	}
	exepath = real_path(exepath)
	return exepath
}

// find_exe_path walks the environment PATH, just like most shell do, it returns
// the absolute path of the executable if found
pub fn find_abs_path_of_executable(exepath string) ?string {
	if exepath == '' {
		return error('expected non empty `exepath`')
	}
	if is_abs_path(exepath) {
		return real_path(exepath)
	}
	mut res := ''
	paths := getenv('PATH').split(path_delimiter)
	for p in paths {
		found_abs_path := join_path(p, exepath)
		if exists(found_abs_path) && is_executable(found_abs_path) {
			res = found_abs_path
			break
		}
	}
	if res.len > 0 {
		return real_path(res)
	}
	return error('failed to find executable')
}

// exists_in_system_path returns `true` if `prog` exists in the system's PATH
pub fn exists_in_system_path(prog string) bool {
	find_abs_path_of_executable(prog) or { return false }
	return true
}

// is_file returns a `bool` indicating whether the given `path` is a file.
pub fn is_file(path string) bool {
	return exists(path) && !is_dir(path)
}

// is_abs_path returns `true` if `path` is absolute.
pub fn is_abs_path(path string) bool {
	if path.len == 0 {
		return false
	}
	$if windows {
		return path[0] == `/` || // incase we're in MingGW bash
		(path[0].is_letter() && path.len > 1 && path[1] == `:`)
	}
	return path[0] == `/`
}

// join_path returns a path as string from input string parameter(s).
[manualfree]
pub fn join_path(base string, dirs ...string) string {
	mut result := []string{}
	result << base.trim_right('\\/')
	for d in dirs {
		result << d
	}
	res := result.join(path_separator)
	unsafe { result.free() }
	return res
}

// walk_ext returns a recursive list of all files in `path` ending with `ext`.
pub fn walk_ext(path string, ext string) []string {
	if !is_dir(path) {
		return []
	}
	mut files := ls(path) or { return [] }
	mut res := []string{}
	separator := if path.ends_with(path_separator) { '' } else { path_separator }
	for file in files {
		if file.starts_with('.') {
			continue
		}
		p := path + separator + file
		if is_dir(p) && !is_link(p) {
			res << walk_ext(p, ext)
		} else if file.ends_with(ext) {
			res << p
		}
	}
	return res
}

// walk recursively traverses the given directory `path`.
// When a file is encountred it will call the callback function with current file as argument.
pub fn walk(path string, f fn (string)) {
	if !is_dir(path) {
		return
	}
	mut files := ls(path) or { return }
	mut local_path_separator := path_separator
	if path.ends_with(path_separator) {
		local_path_separator = ''
	}
	for file in files {
		p := path + local_path_separator + file
		if is_dir(p) && !is_link(p) {
			walk(p, f)
		} else if exists(p) {
			f(p)
		}
	}
	return
}

// log will print "os.log: "+`s` ...
pub fn log(s string) {
	//$if macos {
	// Use NSLog() on macos
	//} $else {
	println('os.log: ' + s)
	//}
}

// mkdir_all will create a valid full path of all directories given in `path`.
pub fn mkdir_all(path string) ? {
	mut p := if path.starts_with(path_separator) { path_separator } else { '' }
	path_parts := path.trim_left(path_separator).split(path_separator)
	for subdir in path_parts {
		p += subdir + path_separator
		if exists(p) && is_dir(p) {
			continue
		}
		mkdir(p) or { return error('folder: $p, error: $err') }
	}
}

// cache_dir returns the path to a *writable* user specific folder, suitable for writing non-essential data.
pub fn cache_dir() string {
	// See: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
	// There is a single base directory relative to which user-specific non-essential
	// (cached) data should be written. This directory is defined by the environment
	// variable $XDG_CACHE_HOME.
	// $XDG_CACHE_HOME defines the base directory relative to which user specific
	// non-essential data files should be stored. If $XDG_CACHE_HOME is either not set
	// or empty, a default equal to $HOME/.cache should be used.
	$if !windows {
		xdg_cache_home := getenv('XDG_CACHE_HOME')
		if xdg_cache_home != '' {
			return xdg_cache_home
		}
	}
	cdir := join_path(home_dir(), '.cache')
	if !is_dir(cdir) && !is_link(cdir) {
		mkdir(cdir) or { panic(err) }
	}
	return cdir
}

// temp_dir returns the path to a folder, that is suitable for storing temporary files.
pub fn temp_dir() string {
	mut path := getenv('TMPDIR')
	$if windows {
		if path == '' {
			// TODO see Qt's implementation?
			// https://doc.qt.io/qt-5/qdir.html#tempPath
			// https://github.com/qt/qtbase/blob/e164d61ca8263fc4b46fdd916e1ea77c7dd2b735/src/corelib/io/qfilesystemengine_win.cpp#L1275
			path = getenv('TEMP')
			if path == '' {
				path = getenv('TMP')
			}
			if path == '' {
				path = 'C:/tmp'
			}
		}
	}
	$if macos {
		// avoid /var/folders/6j/cmsk8gd90pd.... on macs
		return '/tmp'
	}
	$if android {
		// TODO test+use '/data/local/tmp' on Android before using cache_dir()
		if path == '' {
			path = cache_dir()
		}
	}
	if path == '' {
		path = '/tmp'
	}
	return path
}

fn default_vmodules_path() string {
	return join_path(home_dir(), '.vmodules')
}

// vmodules_dir returns the path to a folder, where v stores its global modules.
pub fn vmodules_dir() string {
	paths := vmodules_paths()
	if paths.len > 0 {
		return paths[0]
	}
	return default_vmodules_path()
}

// vmodules_paths returns a list of paths, where v looks up for modules.
// You can customize it through setting the environment variable VMODULES
pub fn vmodules_paths() []string {
	mut path := getenv('VMODULES')
	if path == '' {
		path = default_vmodules_path()
	}
	list := path.split(path_delimiter).map(it.trim_right(path_separator))
	return list
}

// resource_abs_path returns an absolute path, for the given `path`.
// (the path is expected to be relative to the executable program)
// See https://discordapp.com/channels/592103645835821068/592294828432424960/630806741373943808
// It gives a convenient way to access program resources like images, fonts, sounds and so on,
// *no matter* how the program was started, and what is the current working directory.
[manualfree]
pub fn resource_abs_path(path string) string {
	exe := executable()
	dexe := dir(exe)
	mut base_path := real_path(dexe)
	vresource := getenv('V_RESOURCE_PATH')
	if vresource.len != 0 {
		base_path = vresource
	}
	fp := join_path(base_path, path)
	res := real_path(fp)
	unsafe {
		fp.free()
		base_path.free()
	}
	return res
}

pub struct Uname {
pub mut:
	sysname  string
	nodename string
	release  string
	version  string
	machine  string
}

pub fn execute_or_panic(cmd string) Result {
	res := execute(cmd)
	if res.exit_code != 0 {
		eprintln('failed    cmd: $cmd')
		eprintln('failed   code: $res.exit_code')
		panic(res.output)
	}
	return res
}

pub fn execute_or_exit(cmd string) Result {
	res := execute(cmd)
	if res.exit_code != 0 {
		eprintln('failed    cmd: $cmd')
		eprintln('failed   code: $res.exit_code')
		eprintln(res.output)
		exit(1)
	}
	return res
}
