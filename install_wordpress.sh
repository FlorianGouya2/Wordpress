#!/bin/bash
# Script qui installe le système de gestion de contenu (CMS) Wordpress

if [ ! $UID -eq 0 ];then
	echo "Désolé, vous devez être root pour lancer le script"
	exit 1
fi

echo "Mise à jour dépôt paquets APT ..."
apt update
echo "Mise à jour dépôt paquets APT ok"

echo "Installation des paquets APT ..."
apt -y install apache2 php mariadb-server mariadb-client php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-mysql php-curl php-zip php-imagick
echo "Installation des paquets APT ok"

while [ -z $wordpress_download ];
do
read -p "Souhaitez-vous télécharger Wordpress ? Veuillez saisir 'n' si vous avez déjà téléchargé le dossier Wordpress et que vous voulez faire l'installation à partir de ce dernier. Veuillez saisir votre réponse (y/n) : " wordpress_download
done

case $wordpress_download in

	[y] )		
		echo "Téléchargement de Wordpress ..."		
		wget https://fr.wordpress.org/wordpress-latest-fr_FR.tar.gz
		if [ $? -ne 0 ];then
			echo "Désolé, une erreur s'est produite lors du téléchargement de Wordpress"
			exit 3		
		fi
		echo "Téléchargement de Wordpress ok"			
		echo "Décompression du dossier Wordpress ..."	
		tar -xvzf wordpress-latest-fr_FR.tar.gz
		echo "Décompression du dossier Wordpress ok"
		echo "Suppression de l'archive Wordpress ..."
		rm wordpress-latest-fr_FR.tar.gz
		echo "Suppression de l'archive Wordpress ok"
		;;
	[n] )		
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 2
esac

while [ -z $wordpress_path_src ];
do
read -p "Veuillez saisir le chemin complet source du dossier Wordpress : " wordpress_path_src
done

echo "Vérification saisie chemin source ..."
if [ ! -e $wordpress_path_src ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 4
fi
echo "Vérification saisie chemin source ok"

echo "Vérification présence fichiers Wordpress ..."
if [ ! -f $wordpress_path_src/wp-config-sample.php ];then
	echo "Erreur : votre dossier Wordpress doit contenir le fichier wp-config-sample.php"
	exit 5
fi

if [ ! -f $wordpress_path_src/wp-login.php ];then
	echo "Erreur : votre dossier Wordpress doit contenir le fichier wp-login.php"
	exit 6
fi

echo "Vérification présence fichiers Wordpress ok"

while [ -z $wordpress_path_dst ];
do
read -p "Veuillez saisir le chemin complet destination du dossier Wordpress : " wordpress_path_dst
done

echo "Vérification saisie chemin destination ..."
if [ ! -e $wordpress_path_dst ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 7
fi
echo "Vérification saisie chemin destination ok"

while [ -z $wordpress_directory_name ];
do
read -p "Veuillez saisir le nom que portera le dossier Wordpress : " wordpress_directory_name
done

if [ -e $wordpress_path_dst/$wordpress_directory_name ];then
	echo "Suppression du dossier Wordpress existant ..."
	rm -rf $wordpress_path_dst/$wordpress_directory_name
	echo "Suppression du dossier Wordpress existant ok"
fi

echo "Copie du dossier Wordpress ..."
cp -R $wordpress_path_src $wordpress_path_dst/$wordpress_directory_name
echo "Copie du dossier Wordpress ok"

echo "Copie du fichier wp-config-sample.php en wp-config.php ..."
cp $wordpress_path_dst/$wordpress_directory_name/wp-config-sample.php $wordpress_path_dst/$wordpress_directory_name/wp-config.php
echo "Copie du fichier wp-config-sample.php en wp-config.php ok"

echo "Paramétrage des droits sur le dossier Wordpress ..."
chmod -R 777 $wordpress_path_dst/$wordpress_directory_name/
echo "Paramétrage des droits sur le dossier Wordpress ok"

while [ -z $wordpress_bdd_database ];
do
read -p "Veuillez saisir le nom de la base de données Wordpress : " wordpress_bdd_database
done

while [ -z $wordpress_bdd_user ];
do
read -p "Veuillez saisir le nom de l'utilisateur de la base de données Wordpress : " wordpress_bdd_user
done

while [ -z $wordpress_bdd_user_pwd ];
do
read -p "Veuillez saisir le mot de passe de l'utilisateur de la base de données Wordpress : " wordpress_bdd_user_pwd
done

echo "Création et configuration de la base de données ..."

myslqquery="drop user if exists '$wordpress_bdd_user'@'localhost';
	    drop database if exists $wordpress_bdd_database;
	    create database $wordpress_bdd_database;
	    create user '$wordpress_bdd_user'@'localhost' identified by '$wordpress_bdd_user_pwd';
	    grant all privileges on $wordpress_bdd_database.* to '$wordpress_bdd_user'@'localhost';
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

echo "Changement du propriétaire du dossier Wordpress ..."
chown -R www-data:www-data $wordpress_path_dst/$wordpress_directory_name
echo "Changement du propriétaire du dossier Wordpress ok"

read -p "Veuillez renseigner les informations suivantes dans le fichier wp-config.php de Wordpress (paramètres 'define'):  

	  nom de la bdd : $wordpress_bdd_database
	  nom de l'utilisateur de la bdd : $wordpress_bdd_user
	  mot de passe de l'utilisateur de la bdd : $wordpress_bdd_user_pwd

Veuillez appuyer sur la touche 'entrée' pour continuer ..."

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier wp-config.php ."
nano $wordpress_path_dst/$wordpress_directory_name/wp-config.php

while [ -z $wordpress_symbolic_link ];
do
echo "Si votre dossier Wordpress ne se trouve pas dans le répertoire /var/www/html, saisissez 'y' à la question suivante :"
read -p "Faut-il créer un lien symbolique ? (y/n) " wordpress_symbolic_link
done

case $wordpress_symbolic_link in

	[y] )
		if [ -e /var/www/html/wordpress ];then
			echo "Suppression du lien symbolique existant ..."			
			rm -rf /var/www/html/wordpress
			echo "Suppression du lien symbolique existant ok"		
		fi				
		echo "Création du lien symbolique ..."
		mkdir /var/www/html/wordpress		
		ln -s $wordpress_path_dst/$wordpress_directory_name /var/www/html/wordpress 
		echo "Création du lien symbolique ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 8
esac

echo "Redémarrage du service apache2 ..."
/etc/init.d/apache2 restart
echo "Redémarrage du service apache2 ok"

read -p "Vous pouvez à présent ouvrir un navigateur Internet et saisir l'URL suivante pour accèder à l'installation graphique de Wordpress : http://localhost/wordpress . Appuyer sur 'entrée' une fois cette étape terminée ..."
read -p "Si vous avez fait l'installation graphique de Wordpress, veuillez confirmer à nouveau en appuyant sur la touche 'entrée'."

echo "Installation Wordpress ok"

echo "URL page accueil Wordpress : http://localhost/wordpress/index.php"
echo "URL connexion Wordpress : http://localhost/wordpress/wp-login.php"

exit 0