if !executable('xcodebuild') || exists('b:xcode_project') || &cp
    finish
endif

call xb#DetectProject("<afile>", 0)
