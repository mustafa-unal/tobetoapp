import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tobetoapp/bloc/admin/admin_bloc.dart';
import 'package:tobetoapp/bloc/admin/admin_event.dart';
import 'package:tobetoapp/bloc/admin/admin_state.dart';

class LessonEditPage extends StatefulWidget {
  final String lessonId;

  const LessonEditPage({required this.lessonId, super.key});

  @override
  _LessonEditPageState createState() => _LessonEditPageState();
}

class _LessonEditPageState extends State<LessonEditPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isLive;
  String? _imageUrl;
  List<String> _teacherIds = [];
  List<String> _classIds = [];
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadLessonDetails(widget.lessonId));
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate,
      Function(DateTime?) onPicked) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print("Image pick failed: $e");
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson Details'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is LessonImageUploaded) {
            context.read<AdminBloc>().add(LoadLessonDetails(widget.lessonId));
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to upload image: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is LessonDetailsLoaded) {
            if (_titleController.text.isEmpty) {
              _titleController.text = state.lesson.title ?? '';
            }
            if (_descriptionController.text.isEmpty) {
              _descriptionController.text = state.lesson.description ?? '';
            }
            if (_startDate == null) {
              _startDate = state.lesson.startDate;
            }
            if (_endDate == null) {
              _endDate = state.lesson.endDate;
            }
            if (_isLive == null) {
              _isLive = state.lesson.isLive;
            }
            if (_teacherIds.isEmpty) {
              _teacherIds = state.lesson.teacherIds ?? [];
            }
            if (_classIds.isEmpty) {
              _classIds = state.lesson.classIds ?? [];
            }
            if (_imageUrl == null) {
              _imageUrl = state.lesson.image;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _imageFile != null
                        ? Image.file(
                            File(_imageFile!.path),
                            height: 150,
                          )
                        : _imageUrl != null
                            ? Image.network(
                                _imageUrl!,
                                height: 150,
                              )
                            : SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Select Image'),
                    ),
                    if (_imageFile != null)
                      ElevatedButton(
                        onPressed: () {
                          if (_imageFile != null) {
                            context.read<AdminBloc>().add(UploadLessonImage(
                                  lessonId: widget.lessonId,
                                  imageFile: _imageFile!,
                                ));
                          }
                        },
                        child: Text('Upload Image'),
                      ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      title: Text('Start Date'),
                      subtitle: Text(_formatDate(_startDate)),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _pickDate(context, _startDate, (date) {
                        setState(() {
                          _startDate = date;
                        });
                      }),
                    ),
                    ListTile(
                      title: Text('End Date'),
                      subtitle: Text(_formatDate(_endDate)),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _pickDate(context, _endDate, (date) {
                        setState(() {
                          _endDate = date;
                        });
                      }),
                    ),
                    CheckboxListTile(
                      title: Text('Is Live'),
                      value: _isLive ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          _isLive = value;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Assign Teachers',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    DropdownSearch<String>.multiSelection(
                      items: state.teachers
                          .map((teacher) =>
                              '${teacher.firstName} ${teacher.lastName}')
                          .toList(),
                      selectedItems: state.teachers
                          .where((teacher) => _teacherIds.contains(teacher.id))
                          .map((teacher) =>
                              '${teacher.firstName} ${teacher.lastName}')
                          .toList(),
                      onChanged: (selectedItems) {
                        setState(() {
                          _teacherIds = state.teachers
                              .where((teacher) => selectedItems.contains(
                                  '${teacher.firstName} ${teacher.lastName}'))
                              .map((teacher) => teacher.id!)
                              .toList();
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Select Teachers",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      clearButtonProps: ClearButtonProps(
                        isVisible: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Assign Classes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    DropdownSearch<String>.multiSelection(
                      items: state.classes
                          .map((classModel) => classModel.name ?? '')
                          .toList(),
                      selectedItems: state.classes
                          .where(
                              (classModel) => _classIds.contains(classModel.id))
                          .map((classModel) => classModel.name ?? '')
                          .toList(),
                      onChanged: (selectedItems) {
                        setState(() {
                          _classIds = state.classes
                              .where((classModel) =>
                                  selectedItems.contains(classModel.name))
                              .map((classModel) => classModel.id!)
                              .toList();
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Select Classes",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      clearButtonProps: ClearButtonProps(
                        isVisible: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final updatedLesson = state.lesson.copyWith(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          startDate: _startDate,
                          endDate: _endDate,
                          isLive: _isLive,
                          teacherIds: _teacherIds,
                          classIds: _classIds,
                          image: _imageUrl,
                        );
                        context
                            .read<AdminBloc>()
                            .add(UpdateLesson(updatedLesson));
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AdminError) {
            return Center(
                child: Text('Failed to load lesson details: ${state.message}'));
          } else {
            return Center(child: Text('No lesson details found'));
          }
        },
      ),
    );
  }
}