import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';



class CustomErrorWidget extends StatelessWidget {import 'package:flutter_svg/svg.dart';

  final FlutterErrorDetails? errorDetails;

  final String? errorMessage;class CustomErrorWidget extends StatelessWidget {



  const CustomErrorWidget({  final FlutterErrorDetails? errorDetails;import '../core/app_export.dart';

    super.key,

    this.errorDetails,  final String? errorMessage;

    this.errorMessage,

  });// custom_error_widget.dart



  @override  const CustomErrorWidget({

  Widget build(BuildContext context) {

    return Center(    super.key,class CustomErrorWidget extends StatelessWidget {

      child: Card(

        margin: const EdgeInsets.all(16.0),    this.errorDetails,  const CustomErrorWidget({

        child: Padding(

          padding: const EdgeInsets.all(16.0),    this.errorMessage,    super.key

          child: Column(

            mainAxisSize: MainAxisSize.min,  });  });

            children: [

              const Icon(

                Icons.error_outline,

                size: 48,  @override  @override

                color: Colors.red,

              ),  Widget build(BuildContext context) {  Widget build(BuildContext context) {

              const SizedBox(height: 16),

              Text(    return Center(    return Container(); // TODO: Implement widget

                'Có lỗi xảy ra',

                style: Theme.of(context).textTheme.titleLarge,      child: Card(  }

              ),

              const SizedBox(height: 8),        margin: const EdgeInsets.all(16.0),

              Text(

                errorMessage ?? 'Vui lòng thử lại sau',        child: Padding(  final FlutterErrorDetails? errorDetails;

                style: Theme.of(context).textTheme.bodyMedium,

                textAlign: TextAlign.center,          padding: const EdgeInsets.all(16.0),  final String? errorMessage;

              ),

            ],          child: Column(

          ),

        ),            mainAxisSize: MainAxisSize.min,  @override

      ),

    );            children: [

  }

}              const Icon(  @override

                Icons.error_outline,    return Scaffold(

                size: 48,      backgroundColor: const Color(0xFFFAFAFA),

                color: Colors.red,      body: SafeArea(

              ),          child: Center(

              const SizedBox(height: 16),        child: Padding(

              Text(          padding: const EdgeInsets.all(24.0),

                'Có lỗi xảy ra',          child: Column(

                style: Theme.of(context).textTheme.titleLarge,            mainAxisAlignment: MainAxisAlignment.center,

              ),            crossAxisAlignment: CrossAxisAlignment.center,

              const SizedBox(height: 8),            children: [

              Text(              SvgPicture.asset(

                errorMessage ?? 'Vui lòng thử lại sau',                'assets/images/sad_face.svg',

                style: Theme.of(context).textTheme.bodyMedium,                height: 42,

                textAlign: TextAlign.center,                width: 42,

              ),              ),

              if (errorDetails != null) ...[              const SizedBox(height: 8),

                const SizedBox(height: 16),              Text(

                ExpansionTile(                "Something went wrong",

                  title: const Text('Chi tiết lỗi'),                style: const TextStyle(

                  children: [                  fontSize: 24,

                    Padding(                  fontWeight: FontWeight.w500,

                      padding: const EdgeInsets.all(8.0),                  color: Color(0xFF262626),

                      child: Text(                ),

                        errorDetails.toString(),              ),

                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}