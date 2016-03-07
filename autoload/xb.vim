if !executable('xcodebuild') || &cp
    finish
endif


let g:vim_xcodebuild_maxdepth = get(g:, 'vim_xcodebuild_maxdepth', 4)

let s:xcodebuild_cmd = 'xcodebuild %s'

if executable('xcpretty')
    let s:xcpretty_cmd = ' | xcpretty'
else
    let s:xcpretty_cmd = ''
endif

function! xb#DetectProject(file, verbose) abort
    let b:xcode_project = ''

    let cwd = fnamemodify(getcwd(), ':p')
    let bdir = fnamemodify(expand(a:file), ':p:h')
    let level = 1

    while empty(b:xcode_project) && bdir !=# cwd && level < g:vim_xcodebuild_maxdepth
        let b:xcode_project = globpath(bdir, '*.xcodeproj')
        let level = level + 1
        let bdir = fnamemodify(bdir , ':h')
    endwhile

    if empty(b:xcode_project) && strlen(g:xcode_project)
        let b:xcode_project = g:xcode_project
    endif

    if strlen(b:xcode_project)
        if a:verbose
            echo "XcodeProject: " . b:xcode_project
        endif

        call xb#SetupMappings()
    endif
endfunction

function! xb#SetupMappings() abort
    command! -buffer -bang -nargs=? -complete=custom,xb#CompleteActions BuildXcodeProject call xb#BuildProject("<args>", <bang>0)
    command! -buffer -bang -nargs=0 CleanXcodeProject call xb#CleanProject(<bang>0)
    command! -buffer -bang -nargs=0 RunXcodeProject call xb#RunProject(<bang>0)

    nnoremap <buffer> <silent> <LocalLeader>b :BuildXcodeProject!<CR>
    nnoremap <buffer> <silent> <LocalLeader>B :BuildXcodeProject<CR>
    nnoremap <buffer> <silent> <LocalLeader>c :CleanXcodeProject!<CR>
    nnoremap <buffer> <silent> <LocalLeader>C :CleanXcodeProject<CR>
    nnoremap <buffer> <silent> <LocalLeader>r :RunXcodeProject!<CR>
    nnoremap <buffer> <silent> <LocalLeader>R :RunXcodeProject<CR>
endfunction

function! xb#CompleteOptions(A, L, P) abort
    if a:L =~# '\s\+-project\s\+$' || a:L =~# '\s\+-project\s\+[0-9a-zA-Z_\-/\.]\+$'
        return globpath('**', '*.xcodeproj')
    else
        let parts = split(a:L, '\s\+')

        let str = xb#CompleteActions(a:A, a:L, a:P)

        if index(parts, '-project') == -1
            let str = '-project' . "\n" . str
        endif

        return str
    endif
endfunction

function! xb#CompleteActions(A, L, P) abort
    return join(['build', 'analyze', 'archive', 'test', 'installsrc', 'install', 'clean'], "\n")
endfunction

function! xb#HasProject() abort
    return exists('b:xcode_project') && strlen(b:xcode_project)
endfunction

function! xb#Run(cmd) abort
    if has('nvim')
        botright new | call termopen(a:cmd) | startinsert
    else
        execute '!' . a:cmd
    endif
endfunction

function! xb#Build(options, use_xcpretty) abort
    let cmd = s:xcodebuild_cmd . (a:use_xcpretty ? s:xcpretty_cmd : '')
    let cmd = printf(cmd, a:options)
    call xb#Run(cmd)
endfunction

function! xb#BuildProject(action, use_xcpretty) abort
    if xb#HasProject()
        let action = strlen(a:action) ? a:action : 'build'
        let options = printf("-project %s %s", shellescape(b:xcode_project), action)
        call xb#Build(options, a:use_xcpretty)
    endif
endfunction

function! xb#CleanProject(bang) abort
    call xb#BuildProject('clean', a:bang)
endfunction

function! xb#RunProject(bang) abort
    if xb#HasProject()
        let build = finddir('build', b:xcode_project . ';')
        let program = build . '/Release/' . fnamemodify(b:xcode_project, ':t:r')
        let program = fnamemodify(program, ':p')

        if empty(build) || !filereadable(program)
            if has('nvim')
                let options = 'build' . (a:bang ? s:xcpretty_cmd : '')
                call xb#BuildProject(options . ' ; echo ; ' . program, 0)
            else
                silent! !echo
                silent! call xb#BuildProject('build', a:bang)
            endif
        endif

        if executable(program)
            call xb#Run(program)
        endif
    endif
endfunction
