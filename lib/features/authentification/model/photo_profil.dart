class PhotoProfil {
  final int idDocument;
  final int? idSouscription;
  final int idTypeDocument;
  final String sourceTable;
  final int idSource;
  final String nomFichier;
  final String nomOriginal;
  final String cheminFichier;
  final String? typeMime;
  final int tailleFichier;
  final String descriptionDocument;
  final int versionDocument;
  final String dateTelechargement;
  final String statutDocument;
  final String createdAt;
  final String updatedAt;

  PhotoProfil({
    required this.idDocument,
    this.idSouscription,
    required this.idTypeDocument,
    required this.sourceTable,
    required this.idSource,
    required this.nomFichier,
    required this.nomOriginal,
    required this.cheminFichier,
    this.typeMime,
    required this.tailleFichier,
    required this.descriptionDocument,
    required this.versionDocument,
    required this.dateTelechargement,
    required this.statutDocument,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhotoProfil.fromJson(Map<String, dynamic> json) {
    return PhotoProfil(
      idDocument: json['id_document'],
      idSouscription: json['id_souscription'],
      idTypeDocument: json['id_type_document'],
      sourceTable: json['source_table'],
      idSource: json['id_source'],
      nomFichier: json['nom_fichier'],
      nomOriginal: json['nom_original'],
      cheminFichier: json['chemin_fichier'],
      typeMime: json['type_mime'],
      tailleFichier: json['taille_fichier'],
      descriptionDocument: json['description_document'],
      versionDocument: json['version_document'],
      dateTelechargement: json['date_telechargement'],
      statutDocument: json['statut_document'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_document': idDocument,
      'id_souscription': idSouscription,
      'id_type_document': idTypeDocument,
      'source_table': sourceTable,
      'id_source': idSource,
      'nom_fichier': nomFichier,
      'nom_original': nomOriginal,
      'chemin_fichier': cheminFichier,
      'type_mime': typeMime,
      'taille_fichier': tailleFichier,
      'description_document': descriptionDocument,
      'version_document': versionDocument,
      'date_telechargement': dateTelechargement,
      'statut_document': statutDocument,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}