#!/bin/bash

OUT_SCRIPT="ttsetup.sh"
PASSWD_EN=""
PASSWD_READ=""
PASSWD=""
USAGE=""

function print_usage {
	echo "Usage: $0 [-p/--pass password] [-r/--read]"
}

while [[ $# -gt 0 ]]; do
	case $1 in
	-r|--read)
		PASSWD_READ=true
		PASSWD_EN=true
		;;
	-p|--pass)
		shift
		PASSWD="$1"
		PASSWD_EN=true
		;;
	*)
		USAGE=true
		;;
	esac
	shift
done

if [ -n "$PASSWD" ] && [ -n "$PASSWD_READ" ]; then
	USAGE=true
fi

if [ -n "$USAGE" ]; then
	print_usage
	exit 1
fi

if [ -n "$PASSWD_READ" ]; then
	read -sp "Password: " PASSWD
	echo
fi

if [ -n "$PASSWD_EN" ] && [ -z "$PASSWD" ]; then
	echo "Password cannot be empty!"
	exit 2
fi

ARCHIVE=$(tar -cz ttsetup_raw.sh files | base64)

read -r -d '' IN_SCRIPT << EOF
#!/bin/bash

ARCHIVE="${ARCHIVE}"

tmp_dir=\$(mktemp -d)

trap "rm -rf \$tmp_dir" INT

echo "\${ARCHIVE}" | base64 -di | tar -xz -C \$tmp_dir

\$tmp_dir/ttsetup_raw.sh -d \$tmp_dir/files \$@

rm -rf \$tmp_dir
EOF

if [ -z "$PASSWD_EN" ]; then
	echo "${IN_SCRIPT}" > $OUT_SCRIPT
	chmod +x $OUT_SCRIPT
	exit 0
fi

SCRIPT=$(echo "${IN_SCRIPT}" | gpg  --symmetric --cipher-algo AES256 --armor --passphrase $PASSWD --batch -)

cat << EOF > $OUT_SCRIPT
#!/bin/bash
read -sp "Password: " PASSWD
echo

SCRIPT="${SCRIPT}"

EVAL=\$(echo "\${SCRIPT}" | gpg --decrypt --passphrase \$PASSWD --batch - 2>/dev/null)

if [ \$? != 0 ]; then
	echo "Wrong password" >&2; exit 1
fi

eval "\${EVAL}"
EOF

chmod +x $OUT_SCRIPT

