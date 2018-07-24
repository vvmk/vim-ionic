" Added by lgalke 28/02/17 

function! vionic#init() abort
  call vionic#CreateDefaultStyleExt()
  call vionic#CreateEditCommands()
  call vionic#CreateGenerateCommands()
  command! -nargs=* Ng call vionic#ExecuteNgCommand(<q-args>)
endfunction

" The remaining functions are just prefixed by vionic# and suffixed by
" abort. Hope I did not miss any call statement.

function! vionic#ExecuteNgCommand(args) abort
  if g:vionic_use_dispatch == 1
    let prefix = 'Dispatch '
  else 
    let prefix = '!'
  endif
  execute prefix . 'ng ' . a:args
endfunction

function! vionic#CreateEditCommands() abort
  let modes = 
        \[ ['E', 'edit'],
        \  ['S', 'split'],
        \  ['V', 'vsplit'],
        \  ['T', 'tabnew'] ]
  for mode in modes
    " TODO: ionic 4 with angular 6+ uses component.html and page.html, an
    " elegant solution will solve for both.
    let elements_with_relation = 
          \[ ['Component', 'component.ts'],
          \  ['Module', 'module.ts'],
          \  ['Template', 'component.html'],
          \  ['Spec', 'spec.ts'],
          \  ['Stylesheet', 'component.' . g:vionic_stylesheet_format] ]
    for element in elements_with_relation
      silent execute 'command! -nargs=? -complete=customlist,vionic#' . element[0] .'Files ' . mode[0] . element[0] . ' call vionic#EditRelatedFile(<q-args>, "'. mode[1] .'", "' .element[1]. '")'
    endfor
    let elements_without_relation = 
          \[ 'Directive',
          \  'Service',
          \  'Pipe',
          \  'Guard',
          \  'Ng' ]
    for elt in elements_without_relation
      silent execute 'command! -nargs=1 -complete=customlist,vionic#'. elt . 'Files ' mode[0] . elt . ' call vionic#EditFile(<f-args>, "' . mode[1] .'")'
    endfor
  endfor

  command! -nargs=? -complete=customlist,vionic#SpecFiles ESpec call vionic#EditSpecFile(<q-args>, 'edit')
  command! -nargs=? -complete=customlist,vionic#SpecFiles SSpec call vionic#EditSpecFile(<q-args>, 'split')
  command! -nargs=? -complete=customlist,vionic#SpecFiles VSpec call vionic#EditSpecFile(<q-args>, 'vsplit')
  command! -nargs=? -complete=customlist,vionic#SpecFiles TSpec call vionic#EditSpecFile(<q-args>, 'tabnew')
endfunction

function! vionic#CreateGenerateCommands() abort
  let elements = 
        \[ 'Component',
        \  'Template',
        \  'Module',
        \  'Directive',
        \  'Service',
        \  'Pipe',
        \  'Guard',
        \  'Class',
        \  'Interface',
        \  'Enum' ]
  for element in elements
    silent execute 'command! -nargs=1 -bang G' . element . ' call vionic#Generate("'.tolower(element).'", <q-args>)'
  endfor
endfunction

function! vionic#CreateDefaultStyleExt() abort
  let re = "\'" . '(?<=styleExt.:..).+(?=..)' . "\'"
  let g:vionic_stylesheet_format = system(g:gnu_grep . ' -Po ' . re . ' angular.json')[:-2]
  " assuming the correct grep command is set, if this is loaded but no
  " .angular-cli is found, its probably ionic3 (scss)
  if v:shell_error
    let g:vionic_stylesheet_format = 'scss'
  endif
endfunction

function! vionic#CreateDestroyCommand() abort
  silent execute command! -nargs=1 -complete=customlist,vionic#NgFiles call vionic#DestroyElement(<f-args>)
endfunction

" TODO: optional in some places?
function! vionic#ComponentFiles(A,L,P) abort
  return vionic#Files('component.ts', a:A)
endfunction

function! vionic#ModuleFiles(A,L,P) abort
  return vionic#Files('module.ts', a:A)
endfunction

function! vionic#DirectiveFiles(A,L,P) abort
  return vionic#Files('directive.ts', a:A)
endfunction

" TODO: sometimes
function! vionic#TemplateFiles(A,L,P) abort
  return vionic#Files('html', a:A)
endfunction

" TODO: Ionic has Providers insead of (in addition to?) services
function! vionic#ServiceFiles(A,L,P) abort
  return vionic#Files('service.ts', a:A)
endfunction

function! vionic#PipeFiles(A,L,P) abort
  return vionic#Files('pipe.ts', a:A)
endfunction

function! vionic#GuardFiles(A,L,P) abort
  return vionic#Files('guard.ts', a:A)
endfunction

function! vionic#SpecFiles(A,L,P) abort
  return vionic#Files('spec.ts', a:A)
endfunction

function! vionic#NgFiles(A,L,P) abort
  return vionic#Files('ts', a:A)
endfunction

function! vionic#StylesheetFiles(A,L,P) abort
  return vionic#Files(g:vionic_stylesheet_format, a:A)
endfunction

function! vionic#DestroyElement(file) abort
  call vionic#ExecuteNgCommand('d ' . g:global_files[a:file])
endfunction

function! vionic#Generate(type, name) abort
  call vionic#ExecuteNgCommand('g ' . a:type . ' ' . a:name)
endfunction

function! vionic#Files(extension,A) abort
  let path = '.'
  if isdirectory("src")
    let path .= '/src/'
  endif
  if isdirectory("app")
    let path .= '/app/'
  endif
  let files = split(globpath(path, '**/*'. a:A .'*.' . a:extension), "\n")
  let idx = range(0, len(files)-1)
  let g:global_files = {}
  for i in idx
    let g:global_files[fnamemodify(files[i], ':t:r')] = files[i]
  endfor
  call map(files, 'fnamemodify(v:val, ":t:r")')
  return files
endfunction

function! vionic#EditFile(file, command) abort
  let fileToEdit = has_key(g:global_files, a:file)?  g:global_files[a:file] : a:file . '.ts'
  if !empty(glob(fileToEdit))
    execute a:command fileToEdit
  else
    echoerr fileToEdit . ' was not found'
  endif
endfunction

function! vionic#EditFileIfExist(file, command, extension) abort
  let fileToEdit = exists('g:global_files') && has_key(g:global_files, a:file)?  g:global_files[a:file] : a:file
  if !empty(glob(fileToEdit))
    execute a:command fileToEdit
  else
    echoerr fileToEdit . ' was not found'
  endif
endfunction

function! vionic#EditSpecFile(file, command) abort
  "TODO: check the jump list: if the most recent jump was from a file with the
  "same base name (i.e. home.whatever.spec.ts -> home.whatever.html) then
  ":ESpec will jump back. Maybe vim-go's :GoAlternate handles this better.
  let file = a:file
  if file == ''
    let base_file = substitute(expand('%'), '.html', '', '')
    let base_file = substitute(base_file, '.ts', '', '')

    " just cover everything
    let base_file = substitute(base_file, '.css', '', '')
    let base_file = substitute(base_file, '.scss', '', '')
    let base_file = substitute(base_file, '.less', '', '')
    let file = base_file . '.spec.ts'
  endif 
  " TODO: sometimes ionic uses whatever.page.spec.ts
  if expand('%') =~ 'component.spec.ts'
    return
  endif
  call vionic#EditFileIfExist(file, a:command, '.ts')
endfunction

function! vionic#EditRelatedFile(file, command, target_extension) abort
  let file = a:file
  if file == ''
    let source_extension = vionic#GetSourceNgExtension()
    let file = substitute(expand('%'), source_extension,  '.' . a:target_extension, '')
    call vionic#EditFileIfExist(file, a:command, a:target_extension)
  else 
    call vionic#EditFileIfExist(a:file, a:command, a:target_extension)
  endif
endfunction

function! vionic#GetSourceNgExtension() abort
  let extensions = 
        \[ 'component.ts',
        \  'module.ts',
        \  'component.html',
        \  'component.' . g:vionic_stylesheet_format,
        \  'component.spec.ts']
  for extension in extensions
    if expand('%e') =~ extension
      return '.' . extension
    endif
  endfor
  return '\.' . expand('%:e')
endfunction
