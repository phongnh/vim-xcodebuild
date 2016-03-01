if !executable('xcodebuild') || exists('g:loaded_vim_xcodebuild') || &cp
    finish
endif

let g:loaded_vim_xcodebuild = 1

let g:xcode_project = globpath(getcwd(), '*.xcodeproj')

command! -nargs=0 DetectXcodeProject call xb#DetectProject('%', 1)
command! -nargs=* -complete=custom,xb#CompleteOptions XcodeBuild call xb#Build("<args>") 

nnoremap <silent> <LocalLeader>x :XcodeBuild<Space>
nnoremap <silent> <LocalLeader>d :DetectXcodeProject<CR>
