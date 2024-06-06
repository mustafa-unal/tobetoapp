import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tobetoapp/bloc/class/class_event.dart';
import 'package:tobetoapp/bloc/class/class_state.dart';
import 'package:tobetoapp/models/class_model.dart';
import 'package:tobetoapp/repository/class_repository.dart';

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  final ClassRepository _classRepository;
  StreamSubscription<List<ClassModel>>? _classesSubscription;

  ClassBloc(this._classRepository) : super(ClassLoading()) {
    on<LoadClasses>(_loadClasses);
    on<AddClass>(_addClass);
    on<DeleteClass>(_deleteClass);
    on<ClassUpdated>(_onClassesUpdated);
  }

  Future<void> _loadClasses(LoadClasses event, Emitter<ClassState> emit) async {
    emit(ClassLoading());
    _classesSubscription?.cancel();
    _classesSubscription = _classRepository.getClassesStream().listen(
      (classes) {
        print('Loaded classes: ${classes.length}');
        add(ClassUpdated(classes));
      },
      onError: (error) {
        print('Error loading classes: $error');
        emit(ClassOperationFailure(error.toString()));
      },
    );
  }

  void _onClassesUpdated(ClassUpdated event, Emitter<ClassState> emit) {
    print('Classes updated: ${event.classes.length}');
    emit(ClassesLoaded(event.classes));
  }

  Future<void> _addClass(AddClass event, Emitter<ClassState> emit) async {
    try {
      await _classRepository.addClass(event.classModels);
      emit(ClassOperationSuccess());
    } catch (e) {
      emit(ClassOperationFailure(e.toString()));
    }
  }

  Future<void> _deleteClass(DeleteClass event, Emitter<ClassState> emit) async {
    try {
      await _classRepository.deleteClass(event.id);
      emit(ClassOperationSuccess());
    } catch (e) {
      emit(ClassOperationFailure(e.toString()));
    }
  }
}