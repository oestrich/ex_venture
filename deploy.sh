set -e

TEMP=`getopt -o s --long seed -- "$@"`
eval set -- "$TEMP"

while true ; do
  case "$1" in
    -s|--seed)
      echo "seeding";
      seed=true;
      shift ;;

    --) shift ; break ;;
  esac
done

host=$1
echo "Deploying to ${host}";

echo "Copying file"
scp _build/prod/rel/ex_venture/releases/0.28.0/ex_venture.tar.gz deploy@$host:

echo "Stopping ExVenture"
ssh deploy@$host 'sudo systemctl stop exventure'

echo "Un-taring"
ssh deploy@$host 'tar xzf ex_venture.tar.gz  -C ex_venture'

echo "Migrating"
ssh deploy@$host './ex_venture/bin/ex_venture migrate'

if [ $seed ] ; then
  echo "Seeding"
  ssh deploy@$host './ex_venture/bin/ex_venture seed'
fi

echo "Starting ExVenture"
ssh deploy@$host 'sudo systemctl start exventure'
