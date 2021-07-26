Prérequis / informations à savoir avant de lancer le script :

Le script peut télécharger (wget) le dossier Wordpress si l'utilisateur ne l'a pas déjà fait.

SI Wordpress déjà téléchargé : 
_ extraire l'archive
_ le dossier Wordpress doit contenir directement les fichiers wp-config-sample.php et wp-login.php (pas de sous dossier du style : wordpress/wordpress/wp-login.php)
 
_ avoir une VM Linux fonctionnelle
_ avoir une connexion Internet pour le téléchargement des paquets APT nécessaires au fonctionnement de Wordpress

_ connaître l'emplacement du dossier Wordpress (ex : /tmp/wordpress) 
_ connaître l'emplacement de destination de Wordpress (conseillé dans /var/www/html)

_ faire un apt update + apt upgrade

_ droits d'exécution sur le script à mettre
_ script à lancer en tant que root



Description des fonctionnalités du script :

_ test si utilisateur = root
_ mise à jour dépôt paquets APT
_ installation des paquets APT nécessaires au fonctionnement de Wordpress
_ demande si téléchargement de Wordpress (si utilisateur l'a déjà téléchargé, réponse = 'n')
_ demande du chemin source complet du dossier Wordpress + vérification bonne saisie
_ vérification présence dossiers fichiers wp-config-sample.php et wp-login.php dans dossier source
_ demande du chemin destination du dossier Wordpress + vérification bonne saisie
_ demande nom du dossier Wordpress (possibilité de renommer le dossier source)
_ test existence dossier Wordpress : si oui -> suppression
_ copie du dossier Wordpress du chemin source vers chemin destination
_ copie du fichier wp-config-sample.php en wp-config.php
_ paramétrage des droits sur le dossier Wordpress (u=rwx,g=rwx,o=rwx)
_ demande nom de la base de données Wordpress
_ demande nom de l'utilisateur de la base de données Wordpress
_ demande mot de passe de l'utilisateur de la base de données Wordpress
_ création et configuration de la base de données Wordpress
_ a2enmod rewrite
_ utilisateur doit renseigner VirtualHost dans /etc/apache2/apache2.conf (pour répertoire /var/www/html)
_ changement du propriétaire dossier Wordpress (propriétaire = www-data)
_ utilisateur doit renseigner les informations concernant la bdd Wordpress dans le fichier wp-config.php
_ demande si création de lien symbolique si dossier Wordpress pas dans /var/www/html : si oui -> test existence lien symbolique (si oui -> suppression) + création lien symbolique
_ redémarrage du service apache2
_ attente installation graphique Wordpress
_ affichage URL connexion Wordpress
