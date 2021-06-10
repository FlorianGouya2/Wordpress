#!/bin/bash
# Script qui installe le système de gestion de contenu (CMS) Joomla

if [ ! $UID -eq 0 ];then
	echo "Désolé, vous devez être root pour lancer le script"
	exit 1
fi

echo "Mise à jour dépôt paquets APT ..."
apt update
echo "Mise à jour dépôt paquets APT ok"

echo "Installation des paquets APT ..."
apt -y install apache2 php mysql-server mysql-client php-gd php-mbstring php-xml php-mysql php-curl php-zip libapache2-mod-php
echo "Installation des paquets APT ok"


while [ -z $joomla_path_src ];
do
read -p "Veuillez saisir le chemin complet source du dossier Joomla : " joomla_path_src
done

echo "Vérification saisie chemin source ..."
if [ ! -e $joomla_path_src ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 2
fi
echo "Vérification saisie chemin source ok"

echo "Vérification présence fichiers Joomla ..."
if [ ! -d $joomla_path_src/installation ];then
	echo "Erreur : votre dossier Joomla doit contenir le dossier installation"
	exit 3
fi

if [ ! -f $joomla_path_src/index.php ];then
	echo "Erreur : votre dossier Joomla doit contenir le fichier index.php"
	exit 4
fi

if [ ! -d $joomla_path_src/administrator ];then
	echo "Erreur : votre dossier Joomla doit contenir le dossier /administrator"
	exit 5
fi

if [ ! -f $joomla_path_src/administrator/index.php ];then
	echo "Erreur : votre dossier Joomla doit contenir le fichier /administrator/index.php"
	exit 6
fi

echo "Vérification présence fichiers Joomla ok"

while [ -z $joomla_path_dst ];
do
read -p "Veuillez saisir le chemin complet destination du dossier Joomla : " joomla_path_dst
done

echo "Vérification saisie chemin destination ..."
if [ ! -e $joomla_path_dst ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 7
fi
echo "Vérification saisie chemin destination ok"

while [ -z $joomla_directory_name ];
do
read -p "Veuillez saisir le nom que portera le dossier Joomla : " joomla_directory_name
done

if [ -e $joomla_path_dst/$joomla_directory_name ];then
	echo "Suppression du dossier Joomla existant ..."
	rm -rf $joomla_path_dst/$joomla_directory_name
	echo "Suppression du dossier Joomla existant ok"
fi

echo "Copie du dossier Joomla ..."
cp -R $joomla_path_src $joomla_path_dst/$joomla_directory_name
echo "Copie du dossier Joomla ok"

while [ -z $joomla_bdd_database ];
do
read -p "Veuillez saisir le nom de la base de données Joomla : " joomla_bdd_database
done

while [ -z $joomla_bdd_user ];
do
read -p "Veuillez saisir le nom de l'utilisateur de la base de données Joomla : " joomla_bdd_user
done

while [ -z $joomla_bdd_user_pwd ];
do
read -p "Veuillez saisir le mot de passe de l'utilisateur de la base de données Joomla : " joomla_bdd_user_pwd
done

echo "Création et configuration de la base de données ..."

myslqquery="drop user if exists '$joomla_bdd_user'@'localhost';
	    drop database if exists $joomla_bdd_database;
	    create database $joomla_bdd_database;
	    create user '$joomla_bdd_user'@'localhost' identified by '$joomla_bdd_user_pwd';
	    grant all privileges on $joomla_bdd_database.* to '$joomla_bdd_user'@'localhost';
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

echo "Changement du propriétaire du dossier Joomla ..."
chown -R www-data:www-data $joomla_path_dst/$joomla_directory_name
echo "Changement du propriétaire du dossier Joomla ok"

read -p "Veuillez modifier la valeur du paramètre 'output_buffering' à 'off' dans fichier php.ini. Pour une version de php 7.4, il se trouve dans /etc/php/7.4/apache2/. Veuillez appuyer sur la touche 'entrée' pour continuer ..."

while [ -z $joomla_path_php ];
do
read -p "Veuillez saisir le chemin complet du fichier php.ini : " joomla_path_php
done

echo "Vérification saisie chemin php.ini ..."
if [ ! -f $joomla_path_php ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 8
fi
echo "Vérification saisie chemin php.ini ok"

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier php.ini. Rappel : modifier la valeur du paramètre 'output_buffering' à 'off'"
nano $joomla_path_php

while [ -z $joomla_symbolic_link ];
do
echo "Si votre dossier Joomla ne se trouve pas dans le répertoire /var/www/html, saisissez 'y' à la question suivante :"
read -p "Faut-il créer un lien symbolique ? (y/n) " joomla_symbolic_link
done

case $joomla_symbolic_link in

	[y] )
		if [ -e /var/www/html/joomla ];then
			echo "Suppression du lien symbolique existant ..."			
			rm -rf /var/www/html/joomla
			echo "Suppression du lien symbolique existant ok"		
		fi				
		echo "Création du lien symbolique ..."
		mkdir /var/www/html/joomla		
		ln -s $joomla_path_dst/$joomla_directory_name /var/www/html/joomla 
		echo "Création du lien symbolique ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 9
esac

echo "Redémarrage du service apache2 ..."
/etc/init.d/apache2 restart
echo "Redémarrage du service apache2 ok"

read -p "Vous pouvez à présent ouvrir un navigateur Internet et saisir l'URL suivante pour accèder à l'installation graphique de Joomla : http://localhost/joomla . Appuyer sur 'entrée' une fois cette étape terminée ..."
read -p "Si vous avez fait l'installation graphique de Joomla, veuillez confirmer à nouveau en appuyant sur la touche 'entrée'."

echo "Suppression du dossier d'installation de Joomla ..."
rm -R $joomla_path_dst/$joomla_directory_name/installation/
echo "Suppression du dossier d'installation de Joomla ok"

echo "Installation Joomla ok"

echo "URL page accueil Joomla : http://localhost/joomla/joomla/index.php"
echo "URL connexion Joomla : http://localhost/joomla/joomla/administrator/index.php"

exit 0