import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tobetoapp/bloc/lessons/lesson_bloc.dart';
import 'package:tobetoapp/bloc/lessons/lesson_event.dart';
import 'package:tobetoapp/bloc/lessons/lesson_live/live_session_bloc.dart';
import 'package:tobetoapp/bloc/lessons/lesson_live/live_session_event.dart';
import 'package:tobetoapp/bloc/lessons/lesson_live/live_session_state.dart';
import 'package:tobetoapp/bloc/lessons/lesson_state.dart';
import 'package:tobetoapp/bloc/homework/homework_bloc.dart';
import 'package:tobetoapp/bloc/homework/homework_event.dart';
import 'package:tobetoapp/bloc/homework/homework_state.dart';
import 'package:tobetoapp/models/lesson_model.dart';
import 'package:tobetoapp/utils/theme/constants/constants.dart';

class TeacherLiveLessonPage extends StatefulWidget {
  final LessonModel lesson;

  const TeacherLiveLessonPage({super.key, required this.lesson});

  @override
  _TeacherLiveLessonPageState createState() => _TeacherLiveLessonPageState();
}

class _TeacherLiveLessonPageState extends State<TeacherLiveLessonPage> {
  bool showHomework = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    context.read<HomeworkBloc>().add(LoadHomeworks(widget.lesson.id!));
    context
        .read<LiveSessionBloc>()
        .add(FetchLiveSessions(widget.lesson.liveSessions ?? []));
    context.read<LessonBloc>().add(FetchTeachersForLesson(widget.lesson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title ?? 'Kurs Detayları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHomeworkDialog,
          ),
        ],
      ),
      body: BlocListener<HomeworkBloc, HomeworkState>(
        listener: (context, state) {
          if (state is HomeworkSuccess) {
            context.read<HomeworkBloc>().add(LoadHomeworks(widget.lesson.id!));
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              lessonImage(widget.lesson.image),
              lessonDetails(widget.lesson, _showCourseInfoDialog),
              sessionSection(widget.lesson),
              teacherSection(widget.lesson),
              homeworkToggle(showHomework, _toggleHomeworkVisibility),
              if (showHomework) homeworkSection(widget.lesson),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleHomeworkVisibility() {
    setState(() {
      showHomework = !showHomework;
    });
  }

  void _showAddHomeworkDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ödev Ekle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: AppConstants.sizedBoxHeightSmall),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: AppConstants.sizedBoxHeightSmall),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dueDate == null
                        ? 'Teslim Tarihini Seç'
                        : 'Son Teslim Tarihi: ${_formatDate(dueDate)}'),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      setState(() {
                        dueDate = picked;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Ekle'),
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen tüm alanları doldurun.'),
                        ),
                      );
                      return;
                    }

                    final homework = HomeworkModel(
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: dueDate,
                      lessonId: widget.lesson.id,
                    );
                    context.read<HomeworkBloc>().add(AddHomework(homework));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget homeworkSection(LessonModel lesson) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: BlocBuilder<HomeworkBloc, HomeworkState>(
        builder: (context, homeworkState) {
          if (homeworkState is HomeworkLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (homeworkState is HomeworkLoaded) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ödev Adı')),
                  DataColumn(label: Text('Veriliş Tarihi')),
                  DataColumn(label: Text('Son Teslim Tarihi')),
                  DataColumn(label: Text('Gönderen Sayısı')),
                  DataColumn(label: Text('İşlem')),
                ],
                rows: homeworkState.homeworks.map((homework) {
                  return DataRow(cells: [
                    DataCell(Text(homework.title ?? '')),
                    DataCell(Text(homework.assignedDate != null
                        ? _formatDate(homework.assignedDate)
                        : '')),
                    DataCell(Text(homework.dueDate != null
                        ? _formatDate(homework.dueDate)
                        : '')),
                    DataCell(Text(
                        homework.studentSubmissions?.length.toString() ?? '0')),
                    DataCell(Row(
                      children: [
                        TextButton(
                          child: const Text('Düzenle'),
                          onPressed: () => _showEditHomeworkDialog(homework),
                        ),
                        TextButton(
                          child: const Text('Sil'),
                          onPressed: () => context
                              .read<HomeworkBloc>()
                              .add(DeleteHomework(homework.id!, lesson.id!)),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            );
          } else if (homeworkState is HomeworkFailure) {
            return Center(child: Text('Error: ${homeworkState.error}'));
          } else {
            return const Center(child: Text('Unknown error occurred.'));
          }
        },
      ),
    );
  }

  void _showEditHomeworkDialog(HomeworkModel homework) {
    final titleController = TextEditingController(text: homework.title);
    final descriptionController =
        TextEditingController(text: homework.description);
    DateTime? dueDate = homework.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ödevi Düzenle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: AppConstants.sizedBoxHeightSmall),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: AppConstants.sizedBoxHeightSmall),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dueDate == null
                        ? 'Teslim Tarihini Seç'
                        : 'Son Teslim Tarihi: ${_formatDate(dueDate)}'),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      setState(() {
                        dueDate = picked;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Güncelle'),
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen tüm alanları doldurun.'),
                        ),
                      );
                      return;
                    }

                    final updatedHomework = HomeworkModel(
                      id: homework.id,
                      lessonId: homework.lessonId,
                      title: titleController.text,
                      description: descriptionController.text,
                      dueDate: dueDate,
                    );
                    context
                        .read<HomeworkBloc>()
                        .add(UpdateHomework(updatedHomework));
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text('Sil'),
                  onPressed: () {
                    context
                        .read<HomeworkBloc>()
                        .add(DeleteHomework(homework.id!, homework.lessonId!));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCourseInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(widget.lesson.title ?? '')),
          content: lessonInfoDialog(widget.lesson),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih yok';
    return DateFormat('dd MMM yyyy, hh:mm', 'tr').format(date);
  }
}

Widget lessonImage(String? imageUrl) {
  return Image.network(
    imageUrl ?? '',
    width: double.infinity,
    height: AppConstants.screenHeight * 0.25,
    fit: BoxFit.cover,
  );
}

Widget lessonDetails(LessonModel lesson, VoidCallback onShowCourseInfoDialog) {
  return Padding(
    padding: EdgeInsets.all(AppConstants.paddingMedium),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lesson.title ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        OutlinedButton(
          onPressed: onShowCourseInfoDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            side: const BorderSide(color: Colors.purple),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.br8),
            ),
          ),
          child: const Text(
            'DETAY',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget sessionSection(LessonModel lesson) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oturumlar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        BlocBuilder<LiveSessionBloc, LiveSessionState>(
          builder: (context, state) {
            if (state is LiveSessionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LiveSessionLoaded) {
              final liveSessions = state.liveSessions;
              return Column(
                children: liveSessions.map((session) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppConstants.verticalPaddingSmall / 3),
                    child: ExpansionTile(
                      title: Text(session.title ?? 'Oturum'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                              'Başlangıç: ${_formatDate(session.startDate)}'),
                          subtitle:
                              Text('Bitiş: ${_formatDate(session.endDate)}'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            } else if (state is LiveSessionFailure) {
              return Center(child: Text('Error: ${state.error}'));
            } else {
              return const Center(child: Text('Unknown error occurred.'));
            }
          },
        ),
      ],
    ),
  );
}

Widget teacherSection(LessonModel lesson) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school),
            SizedBox(width: AppConstants.sizedBoxWidthSmall),
            Text(
              'Eğitmenler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        BlocBuilder<LessonBloc, LessonState>(
          builder: (context, state) {
            if (state is LessonsLoading) {
              return const CircularProgressIndicator();
            } else if (state is TeachersLoaded) {
              final teachers = state.teachers;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: teachers.map((teacher) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppConstants.verticalPaddingSmall / 2),
                    child: Text(
                      '${teacher.firstName} ${teacher.lastName}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  );
                }).toList(),
              );
            } else if (state is LessonOperationFailure) {
              return const Text('Hata');
            } else {
              return const Text('Bilinmeyen bir hata oluştu.');
            }
          },
        ),
      ],
    ),
  );
}

Widget homeworkToggle(bool showHomework, VoidCallback onToggleHomework) {
  return TextButton(
    onPressed: onToggleHomework,
    child: Row(
      children: [
        const Text(
          'Ödevler',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        Icon(
          showHomework ? Icons.expand_less : Icons.expand_more,
          color: Colors.purple,
        ),
      ],
    ),
  );
}

Widget lessonInfoDialog(LessonModel lesson) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        leading: const Icon(Icons.description),
        title: Text('Açıklama: ${lesson.description ?? 'Yok'}'),
      ),
      ListTile(
        leading: const Icon(Icons.category),
        title: Text('Kategori: ${lesson.category ?? 'Kategori belirtilmemiş'}'),
      ),
      ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text('Başlangıç: ${_formatDate(lesson.startDate)}'),
      ),
      ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text('Bitiş: ${_formatDate(lesson.endDate)}'),
      ),
    ],
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Tarih yok';
  return DateFormat('dd MMM yyyy, hh:mm', 'tr').format(date);
}
