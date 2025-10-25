import 'photo_profil.dart';

class UserModel {
  final int idUtilisateur;
  final String? matricule;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String poste;
  final String type;
  final String service;
  final String dateInscription;
  final String derniereConnexion;
  final bool estAdministrateur;
  final String statutUtilisateur;
  final String createdAt;
  final String updatedAt;
  final PhotoProfil? photoProfil;
  final dynamic cni;
  final dynamic carteProfessionnelle;
  final dynamic ficheSouscription;

  UserModel({
    required this.idUtilisateur,
    this.matricule,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.poste,
    required this.type,
    required this.service,
    required this.dateInscription,
    required this.derniereConnexion,
    required this.estAdministrateur,
    required this.statutUtilisateur,
    required this.createdAt,
    required this.updatedAt,
    this.photoProfil,
    this.cni,
    this.carteProfessionnelle,
    this.ficheSouscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUtilisateur: json['id_utilisateur'],
      matricule: json['matricule'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      poste: json['poste'],
      type: json['type'],
      service: json['service'],
      dateInscription: json['date_inscription'],
      derniereConnexion: json['derniere_connexion'],
      estAdministrateur: json['est_administrateur'],
      statutUtilisateur: json['statut_utilisateur'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      photoProfil: json['photo_profil'] != null 
          ? PhotoProfil.fromJson(json['photo_profil'])
          : null,
      cni: json['cni'],
      carteProfessionnelle: json['carte_professionnelle'],
      ficheSouscription: json['fiche_souscription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_utilisateur': idUtilisateur,
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'poste': poste,
      'type': type,
      'service': service,
      'date_inscription': dateInscription,
      'derniere_connexion': derniereConnexion,
      'est_administrateur': estAdministrateur,
      'statut_utilisateur': statutUtilisateur,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'photo_profil': photoProfil?.toJson(),
      'cni': cni,
      'carte_professionnelle': carteProfessionnelle,
      'fiche_souscription': ficheSouscription,
    };
  }

  String get fullName => '$prenom $nom';
}