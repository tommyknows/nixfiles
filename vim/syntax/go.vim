" nicer colours for testing coverage
hi def      goCoverageCovered    ctermfg=green guifg=#A6E22E
hi def      goCoverageUncover    ctermfg=red guifg=#F92672
" highlight operators
" match single-char operators:          - + % < > ! & | ^ * =
" and corresponding two-char operators: -= += %= <= >= != &= |= ^= *= ==
syn match goOperator /[-+%<>!&|^*=]=\?/
" match / and /=
syn match goOperator /\/\%(=\|\ze[^/*]\)/
" match two-char operators:               << >> &^
" and corresponding three-char operators: <<= >>= &^=
syn match goOperator /\%(<<\|>>\|&^\)=\?/
" match remaining two-char operators: := && || <- ++ --
syn match goOperator /:=\|||\|<-\|++\|--/
hi def link     goPointerOperator   goOperator
hi def link     goVarArgs           goOperator
hi def link     goOperator          Operator
"" Function calls;
syn match goFunctionCall      /\w\+\ze(/ contains=goBuiltins,goDeclaration
hi def link     goFunctionCall      Type
"" Fields;
  " 1. Match a sequence of word characters coming after a '.'
  " 2. Require the following but dont match it: ( \@= see :h E59)
  "    - The symbols: / - + * %   OR
  "    - The symbols: [] {} <> )  OR
  "    - The symbols: \n \r space OR
  "    - The symbols: , : .
  " 3. Have the start of highlight (hs) be the start of matched
  "    pattern (s) offsetted one to the right (+1) (see :h E401)
syn match       goField   /\.\w\+\
      \%(\%([\/\-\+*%]\)\|\
      \%([\[\]{}<\>\)]\)\|\
      \%([\!=\^|&]\)\|\
      \%([\n\r\ ]\)\|\
      \%([,\:.]\)\)\@=/hs=s+1
hi def link    goField              Identifier
