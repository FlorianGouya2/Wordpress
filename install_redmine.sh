#!/bin/bash
# Script qui installe le gestionnaire de tickets Redmine

if [ ! $UID -eq 0 ];then
	echo "Désolé, vous devez être root pour lancer le script"
	exit 1
fi

echo "Mise à jour dépôt paquets APT ..."
apt update
echo "Mise à jour dépôt paquets APT ok"

echo "Installation des paquets APT ..."
apt -y install postgresql postgresql-contrib build-essential zlib1g zlib1g-dev zlibc ruby-zip libssl-dev libyaml-dev libcurl4-openssl-dev ruby gem libapache2-mod-passenger apache2 apache2-dev libapr1-dev libxslt1-dev libpq-dev libxml2-dev ruby-dev vim libmagickwand-dev imagemagick rails mlocate
# apt install gcc
echo "Installation des paquets APT ok"

while [ -z $redmine_path_src ];
do
read -p "Veuillez saisir le chemin complet source du dossier redmine : " redmine_path_src
done

echo "Vérification saisie chemin source ..."
if [ ! -e $redmine_path_src ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 2
fi
echo "Vérification saisie chemin source ok"

echo "Vérification présence fichiers redmine ..."
if [ ! -d $redmine_path_src/config ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier config qui contient les dossiers et fichiers de redmine"
	exit 3
fi

if [ ! -f $redmine_path_src/config/database.yml.example ];then
	echo "Erreur : votre dossier $redmine_path_src doit contenir le fichier database.yml.example (répertoire $redmine_path_src/config)"
	exit 4
fi

if [ ! -d $redmine_path_src/public ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier public"
	exit 5
fi

if [ ! -d $redmine_path_src/public/plugin_assets ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier public/plugin_assets"
	exit 6
fi
if [ ! -d $redmine_path_src/files ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier files"
	exit 7
fi
if [ ! -d $redmine_path_src/log ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier log"
	exit 8
fi
if [ ! -d $redmine_path_src/tmp ];then
	echo "Erreur : votre dossier redmine doit contenir le dossier tmp"
	exit 9
fi
echo "Vérification présence fichiers redmine ok"

while [ -z $redmine_path_dst ];
do
read -p "Veuillez saisir le chemin complet destination du dossier redmine : " redmine_path_dst
done

echo "Vérification saisie chemin destination ..."
if [ ! -e $redmine_path_dst ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 10
fi
echo "Vérification saisie chemin destination ok"

while [ -z $redmine_directory_name ];
do
read -p "Veuillez saisir le nom que portera le dossier redmine : " redmine_directory_name
done

if [ -e $redmine_path_dst/$redmine_directory_name ];then
	echo "Suppression du dossier redmine existant ..."
	rm -rf $redmine_path_dst/$redmine_directory_name
	echo "Suppression du dossier redmine existant ok"
fi

echo "Copie du dossier redmine ..."
cp -R $redmine_path_src $redmine_path_dst/$redmine_directory_name
echo "Copie du dossier redmine ok"

while [ -z $redmine_bdd_database ];
do
read -p "Veuillez saisir le nom de la base de données redmine : " redmine_bdd_database
done

while [ -z $redmine_bdd_user ];
do
read -p "Veuillez saisir le nom de l'utilisateur de la base de données redmine : " redmine_bdd_user
done

while [ -z $redmine_bdd_user_pwd ];
do
read -p "Veuillez saisir le mot de passe de l'utilisateur de la base de données redmine : " redmine_bdd_user_pwd
done

echo "Création et configuration de la base de données ..."

su postgres -c "psql -c \"drop database $redmine_bdd_database;\""
su postgres -c "psql -c \"drop user $redmine_bdd_user;\""
su postgres -c "psql -c \"CREATE ROLE $redmine_bdd_user LOGIN ENCRYPTED PASSWORD '$redmine_bdd_user_pwd' NOINHERIT VALID UNTIL 'infinity';\""
su postgres -c "psql -c \"CREATE DATABASE $redmine_bdd_database WITH ENCODING='UTF8' OWNER=$redmine_bdd_user;\""

echo "Création et configuration de la base de données ok"

read -p "Veuillez rajouter le mot 'trust' à la fin de la ligne 'local all postgres' du fichier pg_hba.conf. Pour une version de postgresql 9.6, il se trouve dans /etc/postgresql/9.6/main/. Veuillez appuyer sur la touche 'entrée' pour continuer ..."

while [ -z $redmine_path_psql ];
do
read -p "Veuillez saisir le chemin complet du fichier pg_hba.conf : " redmine_path_psql
done

echo "Vérification saisie chemin pg_hba.conf ..."
if [ ! -f $redmine_path_psql ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 11
fi
echo "Vérification saisie chemin pg_hba.conf ok"

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier pg_hba.conf. Rappel : il faut rajouter le mot 'trust' à la fin de la ligne 'local all postgres'."
nano $redmine_path_psql

echo "Relancement du service postgresql ..."
/etc/init.d/postgresql reload
echo "Relancement du service postgresql ok"

echo "Copie du fichier database.yml.example en database.yml ..."
cp $redmine_path_dst/$redmine_directory_name/config/database.yml.example $redmine_path_dst/$redmine_directory_name/config/database.yml
echo "Copie du fichier database.yml.example en database.yml ok"

read -p "Veuillez renseigner les informations suivantes dans le fichier config/database.yml de redmine :  
production:
	  adapter: postgresql
	  database: redmine
	  host: localhost
	  username: redmine
	  password: 'your_password'
	  encoding: 'utf8'

Veuillez appuyer sur la touche 'entrée' pour continuer ..."

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier config/database.yml."
nano $redmine_path_dst/$redmine_directory_name/config/database.yml

echo "Configuration de rails ..."
cd $redmine_path_dst/$redmine_directory_name/config/
bundle install
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:load_default_data
echo "Configuration de rails ok"

echo "Changement du propriétaire du dossier redmine ..."
chown -R www-data:www-data $redmine_path_dst/$redmine_directory_name
echo "Changement du propriétaire du dossier redmine ok"

cd $redmine_path_dst/$redmine_directory_name

echo "Paramétrage des droits sur les répertoires redmine ..."
chmod -R 755 files log tmp public/plugin_assets
echo "Paramétrage des droits sur les répertoires redmine ok"

echo "Vérification présence fichiers Gemfile.lock ..."
if [ ! -f Gemfile.lock ];then
	echo "Erreur : le fichier Gemfile.lock n'existe pas"
	exit 12
fi
echo "Vérification présence fichiers Gemfile.lock ok"

echo "Changement du propriétaire du fichier Gemfile.lock ..."
chown www-data:www-data Gemfile.lock
echo "Changement du propriétaire du fichier Gemfile.lock ok"

while [ -z $redmine_symbolic_link ];
do
echo "Si votre dossier redmine ne se trouve pas dans le répertoire /var/www/html, saisissez 'y' à la question suivante :"
read -p "Faut-il créer un lien symbolique ? (y/n) " redmine_symbolic_link
done

case $redmine_symbolic_link in

	[y] )
		if [ -e /var/www/html/redmine ];then
			echo "Suppression du lien symbolique existant ..."			
			rm -rf /var/www/html/redmine
			echo "Suppression du lien symbolique existant ok"		
		fi				
		echo "Création du lien symbolique ..."
		mkdir /var/www/html/redmine		
		ln -s $redmine_path_dst/$redmine_directory_name /var/www/html/redmine 
		echo "Création du lien symbolique ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 13
esac


echo "Création fichier /etc/apache2/sites-available/master.conf ..."
touch /etc/apache2/sites-available/master.conf
echo "Création fichier /etc/apache2/sites-available/master.conf ok"

read -p "Veuillez ajouter le VirtualHost suivant dans le fichier /etc/apache2/sites-available/master.conf :  
	<VirtualHost *:80>

	ServerAdmin admin@example.com
	Servername hostname
	DocumentRoot /var/www/html/

	<Location /redmine>
	RailsEnv production
	RackBaseURI /redmine
	Options -MultiViews
	</Location>

	</VirtualHost>

Veuillez appuyer sur la touche 'entrée' pour continuer ..."

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier /etc/apache2/sites-available/master.conf "
nano /etc/apache2/sites-available/master.conf

updatedb
locate a2enmod

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/sbin"
. /etc/profile

systemctl reload apache2
a2dissite 000-default.conf
systemctl reload apache2
a2ensite master.conf
systemctl reload apache2

read -p "Veuillez ajouter la ligne 'PassengerUser www-data' dans le fichier /etc/apache2/mods-available/passenger.conf. Veuillez appuyer sur la touche 'entrée' pour continuer ..."

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier /etc/apache2/mods-available/passenger.conf "
nano /etc/apache2/mods-available/passenger.conf

echo "Redémarrage du service apache2 ..."
/etc/init.d/apache2 restart
echo "Redémarrage du service apache2 ok"

echo "Installation redmine ok"

echo "Vous pouvez à présent ouvrir un navigateur et accèder à l'interface web de Redmine en tapant cette adresse : http://localhost/redmine"

echo "login : admin
      pwd : admin

      N.B : Le mot de passe admin est à changer après la 1ère connexion"

exit 0
