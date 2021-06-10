#!/bin/bash
# Script qui installe le gestionnaire de tickets osTicket

if [ ! $UID -eq 0 ];then
	echo "Désolé, vous devez être root pour lancer le script"
	exit 1
fi

echo "Mise à jour dépôt paquets APT ..."
apt update
echo "Mise à jour dépôt paquets APT ok"

echo "Installation des paquets APT ..."
apt -y install apache2 php default-mysql-server mysql-common php-imap php-mbstring php-mail-mime php-horde-xml-wbxml
echo "Installation des paquets APT ok"

while [ -z $osticket_path_src ];
do
read -p "Veuillez saisir le chemin complet source du dossier osticket : " osticket_path_src
done

echo "Vérification saisie chemin source ..."
if [ ! -e $osticket_path_src ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 2
fi
echo "Vérification saisie chemin source ok"

echo "Vérification présence fichiers osTicket ..."
if [ ! -d $osticket_path_src/upload ];then
	echo "Erreur : votre dossier osTicket doit contenir uniquement le dossier upload qui contient tous les dossiers et fichiers de osTicket"
	exit 3
fi

if [ ! -d $osticket_path_src/upload/include ];then
	echo "Erreur : votre dossier $osticket_path_src/upload/ doit contenir le dossier upload"
	exit 4
fi

if [ ! -f $osticket_path_src/upload/include/ost-sampleconfig.php ];then
	echo "Erreur : votre dossier $osticket_path_src/upload/include/ doit contenir le fichier ost-sampleconfig.php (répertoire $osticket_path_src/upload/include)"
	exit 5
fi

if [ ! -d $osticket_path_src/upload/setup ];then
	echo "Erreur : votre dossier $osticket_path_src/upload/ doit contenir le dossier setup (dossier d'installation de osTicket)"
	exit 6
fi
echo "Vérification présence fichiers osTicket ok"

while [ -z $osticket_path_dst ];
do
read -p "Veuillez saisir le chemin complet destination du dossier osticket : " osticket_path_dst
done

echo "Vérification saisie chemin destination ..."
if [ ! -e $osticket_path_dst ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 7
fi
echo "Vérification saisie chemin destination ok"

while [ -z $osticket_directory_name ];
do
read -p "Veuillez saisir le nom que portera le dossier osticket : " osticket_directory_name
done

if [ -e $osticket_path_dst/$osticket_directory_name ];then
	echo "Suppression du dossier osTicket existant ..."
	rm -rf $osticket_path_dst/$osticket_directory_name
	echo "Suppression du dossier osTicket existant ok"
fi

echo "Copie du dossier osticket ..."
cp -R $osticket_path_src $osticket_path_dst/$osticket_directory_name
echo "Copie du dossier osticket ok"

while [ -z $osticket_package ];
do
read -p "Avez-vous un package langage français ? (y/n) " osticket_package
done

case $osticket_package in

	[y] )
		while [ -z $osticket_package_fr ];
		do
		read -p "Veuillez saisir le chemin complet du package français : " osticket_package_fr
		done
		echo "Vérification saisie chemin source ..."
		if [ ! -f $osticket_package_fr ];then
			echo "Désolé, le chemin saisi n'est pas valide"
			exit 9
		fi
		echo "Vérification saisie chemin source ok"
		echo "Copie du package langue française ..."
		cp $osticket_package_fr $osticket_path_dst/$osticket_directory_name/upload/include/i18n/
		echo "Copie du package langue française ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 8
esac

while [ -z $osticket_choice_plugin ];
do
read -p "Avez-vous un plugin osTicket ? (y/n) " osticket_choice_plugin
done

case $osticket_choice_plugin in

	[y] )
		while [ -z $osticket_plugin ];
		do
		read -p "Veuillez saisir le chemin complet du plugin osTicket : " osticket_plugin
		done
		echo "Vérification saisie chemin source ..."
		if [ ! -f $osticket_plugin ];then
			echo "Désolé, le chemin saisi n'est pas valide"
			exit 11
		fi
		echo "Vérification saisie chemin source ok"
		echo "Copie du plugin osTicket ..."
		cp $osticket_plugin $osticket_path_dst/$osticket_directory_name/upload/include/plugins/
		echo "Copie du plugin osTicket ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 10
esac

echo "Copie du fichier ost-sampleconfig.php en ost-config.php ..."
cp $osticket_path_dst/$osticket_directory_name/upload/include/ost-sampleconfig.php $osticket_path_dst/$osticket_directory_name/upload/include/ost-config.php
echo "Copie du fichier ost-sampleconfig.php en ost-config.php ok"

read -p "Veuillez décommenter la ligne 'extension=mysqli' du fichier php.ini. Pour une version de php 7.0, il se trouve dans /etc/php/7.0/apache2/. Veuillez appuyer sur la touche 'entrée' pour continuer ..."

while [ -z $osticket_path_php ];
do
read -p "Veuillez saisir le chemin complet du fichier php.ini : " osticket_path_php
done

echo "Vérification saisie chemin php.ini ..."
if [ ! -f $osticket_path_php ];then
	echo "Désolé, le chemin saisi n'est pas valide"
	exit 12
fi
echo "Vérification saisie chemin php.ini ok"

read -p "Veuillez appuyer sur la touche 'entrée' pour ouvrir le fichier php.ini. Rappel : la ligne extension=mysqli est à décommenter "
nano $osticket_path_php

echo "Changement du propriétaire du dossier osTicket ..."
chown -R www-data:www-data $osticket_path_dst/$osticket_directory_name
echo "Changement du propriétaire du dossier osTicket ok"

echo "Paramétrage des droits sur le fichier ost-config.php ..."
chmod 666 $osticket_path_dst/$osticket_directory_name/upload/include/ost-config.php 
echo "Paramétrage des droits sur le fichier ost-config.php ok"

while [ -z $osticket_symbolic_link ];
do
echo "Si votre dossier osTicket ne se trouve pas dans le répertoire /var/www/html, saisissez 'y' à la question suivante :"
read -p "Faut-il créer un lien symbolique ? (y/n) " osticket_symbolic_link
done

case $osticket_symbolic_link in

	[y] )
		if [ -e /var/www/html/osticket ];then
			echo "Suppression du lien symbolique existant ..."			
			rm -rf /var/www/html/osticket
			echo "Suppression du lien symbolique existant ok"		
		fi				
		echo "Création du lien symbolique ..."
		mkdir /var/www/html/osticket		
		ln -s $osticket_path_dst/$osticket_directory_name /var/www/html/osticket 
		echo "Création du lien symbolique ok"
		;;
	[n] )
		;;
	* )	echo "Désolé, nous n'avons pas compris votre saisie"
		exit 13
esac

echo "Redémarrage du service apache2 ..."
/etc/init.d/apache2 restart
echo "Redémarrage du service apache2 ok"

while [ -z $osticket_bdd_database ];
do
read -p "Veuillez saisir le nom de la base de données osTicket : " osticket_bdd_database
done

while [ -z $osticket_bdd_user ];
do
read -p "Veuillez saisir le nom de l'utilisateur de la base de données osTicket : " osticket_bdd_user
done

while [ -z $osticket_bdd_user_pwd ];
do
read -p "Veuillez saisir le mot de passe de l'utilisateur de la base de données osTicket : " osticket_bdd_user_pwd
done

echo "Création et configuration de la base de données ..."

myslqquery="drop user if exists '$osticket_bdd_user'@'localhost';
	    drop database if exists $osticket_bdd_database;
	    create database $osticket_bdd_database;
	    create user '$osticket_bdd_user'@'localhost' identified by '$osticket_bdd_user_pwd';
	    grant all privileges on $osticket_bdd_database.* to '$osticket_bdd_user'@'localhost';
	    flush privileges;"

mysql -u root -e "$myslqquery" 

echo "Création et configuration de la base de données ok"

read -p "Vous pouvez à présent ouvrir un navigateur Internet et saisir l'URL suivante pour accèder à l'installation graphique de osTicket : http://localhost/osticket/upload/login.php . Appuyer sur 'entrée' une fois cette étape terminée ..."
read -p "Si vous avez fait l'installation graphique de osTicket, veuillez confirmer à nouveau en appuyant sur la touche 'entrée'."

echo "Re-paramétrage des droits sur le fichier ost-config.php ..."
chmod 644 $osticket_path_dst/$osticket_directory_name/upload/include/ost-config.php 
echo "Re-paramétrage des droits sur le fichier ost-config.php ok"

echo "Suppression du dossier d'installation de osTicket ..."
rm -R $osticket_path_dst/$osticket_directory_name/upload/setup/
echo "Suppression du dossier d'installation de osTicket ok"

echo "Installation osTicket ok"

echo "URL osTicket Support Center : http://localhost/osticket/upload/"
echo "URL connexion compte utilisateur : http://localhost/osticket/upload/login.php"
echo "URL connexion compte technicien : http://localhost/osticket/upload/scp/login.php"

exit 0