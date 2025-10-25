set last $status
if test $last -eq 0
    sfx good
else
    sfx bad
end
return $last
