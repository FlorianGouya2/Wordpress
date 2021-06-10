#!/bin/bash
# Script qui installe le système de gestion de contenu (CMS) Drupal

if [ ! $UID -eq 0 ];then
	echo "Désolé, vous devez être root pour lancer le script"
	exit 1
fi

echo "Mise à jour dépôt paquets APT ..."
apt update
echo "Mise à jour dépôt paquets APT ok"

echo "Installation des paquets APT ..."
apt -y install apache2 php mysql-server mysql-client php-mbstring php-xml php-mysql php-gd libapache2-mod-php
echo "Installation des paquets APT ok"

while [ -z $drupal_path_src ];
do
read -p "Veuillez saisir le chemin complet source du dossier Drupal : " drupal_path_src
done

echo "Vérification saisie chemin source ..."
if [ ! -e $drupal_path_src ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 2
fi
echo "Vérification saisie chemin source ok"

echo "Vérification présence fichiers Drupal ..."
if [ ! -d $drupal_path_src/sites ];then
	echo "Erreur : votre dossier Drupal doit contenir le dossier /sites"
	exit 3
fi

if [ ! -d $drupal_path_src/sites/default ];then
	echo "Erreur : votre dossier $drupal_path_src/sites doit contenir le dossier /default"
	exit 4
fi

if [ ! -f $drupal_path_src/sites/default/default.settings.php ];then
	echo "Erreur : votre dossier $drupal_path_src/sites/default/ doit contenir le fichier default.settings.php"
	exit 5
fi

if [ ! -d $drupal_path_src/core ];then
	echo "Erreur : votre dossier Drupal doit contenir le dossier /core"
	exit 6
fi

if [ ! -f $drupal_path_src/core/install.php ];then
	echo "Erreur : votre dossier $drupal_path_src/core/ doit contenir le fichier install.php"
	exit 7
fi

echo "Vérification présence fichiers Drupal ok"

while [ -z $drupal_path_dst ];
do
read -p "Veuillez saisir le chemin complet destination du dossier Drupal : " drupal_path_dst
done

echo "Vérification saisie chemin destination ..."
if [ ! -e $drupal_path_dst ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 8
fi
echo "Vérification saisie chemin destination ok"

while [ -z $drupal_directory_name ];
do
read -p "Veuillez saisir le nom que portera le dossier Drupal : " drupal_directory_name
done

if [ -e $drupal_path_dst/$drupal_directory_name ];then
	echo "Suppression du dossier Drupal existant ..."
	rm -rf $drupal_path_dst/$drupal_directory_name
	echo "Suppression du dossier Drupal existant ok"
fi

echo "Copie du dossier Drupal ..."
cp -R $drupal_path_src $drupal_path_dst/$drupal_directory_name
echo "Copie du dossier Drupal ok"

mkdir $drupal_path_dst/$drupal_directory_name/sites/default/files
mkdir $drupal_path_dst/$drupal_directory_name/sites/default/files/translations

while [ -z $drupal_package ];
do
read -p "Avez-vous un package langage français ? (y/n) " drupal_package
done

case $drupal_package in

	[y] )
		while [ -z $drupal_package_fr ];
		do
		read -p "Veuillez saisir le chemin complet du package français : " drupal_package_fr
		done
		echo "Vérification saisie chemin source ..."
		if [ ! -f $drupal_package_fr ];then
			echo "Désolé, le chemin saisi n'est pas valide"
			exit 10
		fi
		echo "Vérification saisie chemin source ok"
		echo "Copie du package langue française ..."
		cp $drupal_package_fr $drupal_path_dst/$drupal_directory_name/sites/default/files/translations/
		echo "Copie du package langue française ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 9
esac

echo "Copie du fichier default.settings.php en settings.php ..."
cp $drupal_path_dst/$drupal_directory_name/sites/default/default.settings.php $drupal_path_dst/$drupal_directory_name/sites/default/settings.php
echo "Copie du fichier default.settings.php en settings.php ok"

echo "Paramétrage des droits sur le dossier Drupal ..."
chmod -R 777 $drupal_path_dst/$drupal_directory_name/
echo "Paramétrage des droits sur le dossier Drupal ok"

while [ -z $drupal_bdd_database ];
do
read -p "Veuillez saisir le nom de la base de données Drupal : " drupal_bdd_database
done

while [ -z $drupal_bdd_user ];
do
read -p "Veuillez saisir le nom de l'utilisateur de la base de données Drupal : " drupal_bdd_user
done

while [ -z $drupal_bdd_user_pwd ];
do
read -p "Veuillez saisir le mot de passe de l'utilisateur de la base de données Drupal : " drupal_bdd_user_pwd
done

echo "Création et configuration de la base de données ..."

myslqquery="drop user if exists '$drupal_bdd_user'@'localhost';
	    drop database if exists $drupal_bdd_database;
	    create database $drupal_bdd_database;
	    create user '$drupal_bdd_user'@'localhost' identified by '$drupal_bdd_user_pwd';
	    grant all privileges on $drupal_bdd_database.* to '$drupal_bdd_user'@'localhost';
	    flush privileges;"

mysql -u root -e "$myslqquery" 

echo "Création et configuration de la base de données ok"

a2enmod rewrite

read -p "Veuillez ajouter la directive apache suivante dans le fichier /etc/apache2/apache2.conf :  
	<Directory /var/www/html>
		AllowOverride All
	</Directory>

Veuillez appuyer sur la touche 'entrée' pour continuer ..."

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier /etc/apache2/apache2.conf "
nano /etc/apache2/apache2.conf

echo "Changement du propriétaire du dossier Drupal ..."
chown -R www-data:www-data $drupal_path_dst/$drupal_directory_name
echo "Changement du propriétaire du dossier Drupal ok"

while [ -z $drupal_symbolic_link ];
do
echo "Si votre dossier Drupal ne se trouve pas dans le répertoire /var/www/html, saisissez 'y' à la question suivante :"
read -p "Faut-il créer un lien symbolique ? (y/n) " drupal_symbolic_link
done

case $drupal_symbolic_link in

	[y] )
		if [ -e /var/www/html/drupal ];then
			echo "Suppression du lien symbolique existant ..."			
			rm -rf /var/www/html/drupal
			echo "Suppression du lien symbolique existant ok"		
		fi				
		echo "Création du lien symbolique ..."
		mkdir /var/www/html/drupal		
		ln -s $drupal_path_dst/$drupal_directory_name /var/www/html/drupal 
		echo "Création du lien symbolique ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 11
esac

echo "Redémarrage du service apache2 ..."
/etc/init.d/apache2 restart
echo "Redémarrage du service apache2 ok"

read -p "Vous pouvez à présent ouvrir un navigateur Internet et saisir l'URL suivante pour accèder à l'installation graphique de Drupal : http://localhost/drupal/core/install.php . Appuyer sur 'entrée' une fois cette étape terminée ..."
read -p "Si vous avez fait l'installation graphique de Drupal, veuillez confirmer à nouveau en appuyant sur la touche 'entrée'."

echo "Re-paramétrage des droits sur le dossier sites/default ..."
chmod -R 755 $drupal_path_dst/$drupal_directory_name/sites/default
echo "Re-paramétrage des droits sur le dossier sites/default ok"

echo "Re-paramétrage des droits sur le dossier sites/default/files ..."
chmod -R 777 $drupal_path_dst/$drupal_directory_name/sites/default/files 
echo "Re-paramétrage des droits sur le dossier sites/default/files ok"

echo "Installation Drupal ok"

echo "URL connexion Drupal : http://localhost/drupal/user/login"

exit 0