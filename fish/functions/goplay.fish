cd (mktemp -d)

go mod init playground

echo 'package main

func main() {

}' > main.go

vim main.go +4
