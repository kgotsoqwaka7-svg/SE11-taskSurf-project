import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class PostTaskScreen extends StatefulWidget {

  const PostTaskScreen({Key? key}) : super(key:key);




  // This widget is the root of my application.
  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();

}

class _PostTaskScreenState extends State<PostTaskScreen> {
final _formKey = GlobalKey<FormState>();


// this  the form controller
 final _titleController =  TextEditingController();
final _budgetController =  TextEditingController();
final  _locationController =  TextEditingController();
 final  _descriptionController =  TextEditingController();

//the state of the task variables
  String ? _selectedCategory;
  DateTime ? _selectedDateTime;
  bool _isUrgent = false;
  bool _isLoading = false;

//categoires 
  final List<Map<String, dynamic>> _categories = [
{'name':'Cleaning','icon':Icons.cleaning_services_outlined},
{'name':'Repairs','icon':Icons.build_outlined},
{'name':'Gardening','icon':Icons.eco_outlined},
{'name':'Delivery','icon':Icons.inventory_2_outlined},
{'name':'Painting','icon':Icons.format_paint_outlined},
{'name':'Shopping','icon':Icons.shopping_cart_outlined},
{'name':'Pet Care','icon':Icons.pets},
{'name':'Tech Help','icon':Icons.computer_outlined},
  ];


@override

  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

//this will pick the date and time
  Future<void> _pickDateTime() async{

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
     firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days:365)),
    );

    if(pickedDate != null) {
     final pickedTime  = await showTimePicker (context: context, initialTime:TimeOfDay.now()
     );


     if(pickedTime != null) {
      setState(() {

      _selectedDateTime = DateTime (
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      });
     }
    }
  }
//p this will post task to the database firebase
  Future<void> _submitTask() async {

    if(!_formKey.currentState!.validate()) return;

    if(_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    // ignore: dead_code
    if(_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }
    setState(() => _isloading = true);

    try {
    final currentUser = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('tasks').add({
      'title': _titleController.text.trim(),
      'category':_selectedCategory,
      'budget':double.tryParse(_budgetController.text.replaceAll('R','').trim()) ?? 0.0,
      'date': Timestamp.fromDate(_selectedDateTime!),
      'location':_locationController.text.trim(),
      'description':_descriptionController.text.trim(),
      'isUrgent':_isUrgent,
      'status':'open',
      'posterId':currentUser?.uid ?? 'anonymous_user',
      'createdAt':FieldValue.serverTimestamp(),

    });

    if(mounted) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task successfully posted')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedCategory = null;
        _selectedDateTime = null;
        _isUrgent = false;
      });
    }
  }catch(e) {
if(mounted) setState(() => _isLoading = false);
  }
}

@override
Widget build(BuildContext context) {
final themeColor = const Color(0xFFF7F9FC),
appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0;
  title:const Text (
    'TaskSurf',
    style: TextStyle(color: Colors.black, fontWeight:FontWeight.bold),
    ),
    leading:Padding(
      padding: const EdgeInsert.all(8.0),
      child: backgroundColor,themeColor,
      child const Icon(Icons.surfing, color: Colors.white, size:20),
    ),
),

actions:[
  Padding (
    padding:const EdgeInsets.only(right:16.0),
    child:CircleAvatar(
      background:themeColor,
      child:const Text('M', style: TextStyle(color:Colors.white)),
    ),
  )
],
),

body:Form(
  key:_formKey,
  // ignore: sort_child_properties_last
  child:SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child Column(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        // this would be the title of the Task
        _buildLabel('TASK TITLE *'),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(''),
          validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
        );
        const SizedBox(height:16),
        // category
        _buildLabel('CATEGORY *'),
        GridView.builder(
          shrinking: true,
          physics: const NeverScrollableScrollPhysics();
          gridDelegate: const SliverConstrainedCrossAxisCount(themeColorcrossAxisCount: 4,
          childAspectRatio: 1.1,
          crossAspectsSpacing: 8,
          mainAxisSpacing: 8,
          ),

          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat =_categories[index];
            final isSelected = _selectedCategory == cat['name'];
            return InkWell(
              onTap: () => setState (()= _selectedCategory  = cat['cat']),
              borderRadius : BorderRadius.circular(12),
              child:Container(
                decoration: BoxDecoration (
                  color: isSelected ? themeColor : withOpacity(0.1) : Colorswhite,
                  border: Border.all (
                    color: isSelected ? themeColor : Colors.grey.shade300,
                    width: isSelected ? 2: 1,
            ),
            child : Column (
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'], color: isSelected ? themeColor: Colors.grey.shade600, size: 22),
                const SizedBox(height: 4)
                Text(
                  cat['name'],
                  style: TextStyle(themeColorfontSize: 11,
                  color: isSelected ? themeColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
       },
    ),

    const SizedBox(height:16),
    //budget and date/ time row 

    Row(
      children: [
        Expanded(
          child:Column (
            CrossAxisAlignment: CrossAlignment.start,
            children: [
              _buildLabel('BUDGET *'),
              TextFormField(
                controller: _budgetController,
                keyboardType:TextInputType.number,
                decoration: _inputDecoration('e.g. R350'),
                validator: (val) => val null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(width:12),
        Expanded (
          child Column (
            crossAxisAlignment: CrossAlignment.start,
            children: [
              _buildLabel('DATE & TIME *'),
              InkWell (
                onTap: pickDateTime,
                child: InputDecorator(
                  decoration: _inputDecoration('mm/dd/yyyy --:--'),
                  child Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded (
                        child: Text (
                          _selecteddateTime == null
                          ? 'mm/dd/yyyy --:--' 
                          : '${_selectedDateTime!.month}/ ${_selectedDateTime!.day}/${_selectedDateTime!.year} ${_selectedDateTime!.hour}:
                          ${_selectedDateTime!.minute.toString().padLeft(2,'0')},
                          style:TextStyle(
                          fontSize: 12,
                          color: _selectedDateTime == null ? Colors.grey : Colors.black,
                          ),
                          overflow: TextOverFlow.ellipsis,
                        ),
                      ),
                      const icon(Icons.calender_today_outlined, size: 16, color: Colors.grey),
                    ],
                ),
              ),
              ),
            ],

          ),
        ),

      ],
),
const SizedBox(height: 16),
//location
_buildLabel('LOCATION*'),
TextFormField (
controller: _locationController,
decoration:_inputDecoration('e.g. Bellville, Cape Town'),
validator: (val) => val ==null  || val.isEmpty() ? 'Location is required' : null,
),
const SizedBox(height:16),
//description
_buildLabel('Description'),
TextFormField(
controller:_descriptionController,
maxLines: 3,
decoration: _inputDecoration('What needs doing? Materials available, access info...'),
),
const SizedBox(height:16),
//mark urgent toggle
Container(
decoration:BoxDecoration(
Color:Colors,white,
border:Border.all(color: Colors.grey.shade300),
borderRadius: BorderRadius.circular(12),
),
child: SwitchedListTile (
value: _isUrgent,
activeColor: themeColor,
onChanged: (val) => setState (() => _isUrgent = val),
title: const Text  (
'Highlighted to workers nearby',
style: TextStyle(fontSize: 12, color: Colors.grey),
),
),
),

const SizedBox(height:24),
//post button

SizedBox(
width:double.infinity,
height:50,
child:ElevateddButton (
onPressed@ _isLoading ? null : _submitTask,
style: ElevatedButton.styleFrom(
backgroundColor:themeColor,
shape: RoundedRectangleBorder (
borderRadius:BorderRadius.circular(12),
),
),
child: _isLoading
? const CircularProgressIndicator(color: Colors.white)
: const Text ( 'Post Task - It Free',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
),
),
},
                    ],
                    ),
                    ),
                    ),
                    ),
                    }

Widget _buildLabel(String text) {

return Padding (
padding: const EdgeInsets.only(bottom:6.0)
child: Text(
fontSize :12,
fontweight:Fonteight.bold,
color:Colors.grey,

),
                     ),
                        ),
}


InputDecoration _inputDecoration(String hint) {
return InputDecoration (
hintText: hint,
hintStyle:const TextStyle(color: Colors.grey,fontSize:13),
filled:true,
fillColor:Colors.white,
contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical:12),
border:OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide:BorderSide(color:Colors.grey.shade300),
),
enabledBorder:OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide:BorderSide(color:Colors.grey.shade300),
),
focusedBorder:OutlineInputBorder(
borderRadius:BorderRadius.circular(10),
borderSide: const BorderSide(color: Color(0xFF5371E8)),
 ),
),
}
}
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
      