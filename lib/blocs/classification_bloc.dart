import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/classification_model.dart';
import '../services/api_service_old.dart';

// ===== EVENTS =====
abstract class ClassificationEvent extends Equatable {
  const ClassificationEvent();

  @override
  List<Object> get props => [];
}

class LoadCategoriesByGroup extends ClassificationEvent {
  final String groupId;

  const LoadCategoriesByGroup({required this.groupId});

  @override
  List<Object> get props => [groupId];
}

class LoadServicesByCategory extends ClassificationEvent {
  final String categoryId;
  final String? categoryName;

  const LoadServicesByCategory({required this.categoryId, this.categoryName});

  @override
  List<Object> get props => [categoryId, categoryName ?? ''];
}

class LoadAllGroups extends ClassificationEvent {
  const LoadAllGroups();
}

class ClearClassificationData extends ClassificationEvent {
  const ClearClassificationData();
}

// ===== STATES =====
abstract class ClassificationState extends Equatable {
  const ClassificationState();

  @override
  List<Object> get props => [];
}

class ClassificationInitial extends ClassificationState {}

class ClassificationLoading extends ClassificationState {}

class CategoriesLoaded extends ClassificationState {
  final List<CategorieModel> categories;
  final String groupId;

  const CategoriesLoaded({required this.categories, required this.groupId});

  @override
  List<Object> get props => [categories, groupId];
}

class ServicesLoaded extends ClassificationState {
  final List<ServiceModel> services;
  final String categoryId;

  const ServicesLoaded({required this.services, required this.categoryId});

  @override
  List<Object> get props => [services, categoryId];
}

class GroupsLoaded extends ClassificationState {
  final List<GroupeModel> groups;

  const GroupsLoaded({required this.groups});

  @override
  List<Object> get props => [groups];
}

class ClassificationError extends ClassificationState {
  final String message;

  const ClassificationError({required this.message});

  @override
  List<Object> get props => [message];
}

// ===== BLOC =====
class ClassificationBloc
    extends Bloc<ClassificationEvent, ClassificationState> {
  ClassificationBloc() : super(ClassificationInitial()) {
    on<LoadCategoriesByGroup>(_onLoadCategoriesByGroup);
    on<LoadServicesByCategory>(_onLoadServicesByCategory);
    on<LoadAllGroups>(_onLoadAllGroups);
    on<ClearClassificationData>(_onClearClassificationData);
  }

  Future<void> _onLoadCategoriesByGroup(
    LoadCategoriesByGroup event,
    Emitter<ClassificationState> emit,
  ) async {
    emit(ClassificationLoading());

    try {
      print('🔄 Chargement des catégories pour le groupe: ${event.groupId}');

      final categories = await ApiService.getCategoriesByGroupe(event.groupId);

      print(
        '✅ ${categories.length} catégories chargées pour le groupe ${event.groupId}',
      );

      emit(CategoriesLoaded(categories: categories, groupId: event.groupId));
    } catch (e) {
      print('❌ Erreur chargement catégories: $e');
      emit(
        ClassificationError(message: 'Erreur de chargement des catégories: $e'),
      );
    }
  }

  Future<void> _onLoadServicesByCategory(
    LoadServicesByCategory event,
    Emitter<ClassificationState> emit,
  ) async {
    emit(ClassificationLoading());

    try {
      print(
        '🔄 Chargement des services pour la catégorie: ${event.categoryId}',
      );

      final services = await ApiService.getServicesByCategorie(
        event.categoryId,
        event.categoryName,
      );

      print(
        '✅ ${services.length} services chargés pour la catégorie ${event.categoryId}',
      );

      emit(ServicesLoaded(services: services, categoryId: event.categoryId));
    } catch (e) {
      print('❌ Erreur chargement services: $e');
      emit(
        ClassificationError(message: 'Erreur de chargement des services: $e'),
      );
    }
  }

  Future<void> _onLoadAllGroups(
    LoadAllGroups event,
    Emitter<ClassificationState> emit,
  ) async {
    emit(ClassificationLoading());

    try {
      print('🔄 Chargement de tous les groupes');

      // Pour l'instant, on retourne les groupes statiques
      // TODO: Implémenter l'API pour charger tous les groupes
      final groups = [
        const GroupeModel(id: '1', nom: 'Métiers'),
        const GroupeModel(id: '2', nom: 'Freelance'),
        const GroupeModel(id: '3', nom: 'E-marché'),
      ];

      print('✅ ${groups.length} groupes chargés');

      emit(GroupsLoaded(groups: groups));
    } catch (e) {
      print('❌ Erreur chargement groupes: $e');
      emit(
        ClassificationError(message: 'Erreur de chargement des groupes: $e'),
      );
    }
  }

  Future<void> _onClearClassificationData(
    ClearClassificationData event,
    Emitter<ClassificationState> emit,
  ) async {
    emit(ClassificationInitial());
  }
}
