augroup tiltfile_ft
    au!
    autocmd BufNewFile,BufRead Tiltfile,*/Tiltfile setfiletype tiltfile
    autocmd BufNewFile,BufRead Tiltfile,*/Tiltfile set syntax=python
augroup END
