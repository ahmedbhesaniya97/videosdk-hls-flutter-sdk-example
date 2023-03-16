import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/api.dart';
import 'package:videosdk_hls_flutter_example/utils/spacer.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/hls_indicator.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/recording_indicator.dart';

class MeetingAppBar extends StatefulWidget {
  final Room meeting;
  final String recordingState;
  final String hlsState;
  const MeetingAppBar(
      {Key? key,
      required this.meeting,
      required this.recordingState,
      required this.hlsState})
      : super(key: key);

  @override
  State<MeetingAppBar> createState() => MeetingAppBarState();
}

class MeetingAppBarState extends State<MeetingAppBar> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: Row(
        children: [
          if (widget.recordingState == "RECORDING_STARTING" ||
              widget.recordingState == "RECORDING_STOPPING" ||
              widget.recordingState == "RECORDING_STARTED")
            RecordingIndicator(recordingState: widget.recordingState),
          if (widget.recordingState == "RECORDING_STARTING" ||
              widget.recordingState == "RECORDING_STOPPING" ||
              widget.recordingState == "RECORDING_STARTED")
            const HorizontalSpacer(),
          if (widget.hlsState == "HLS_STARTING" ||
              widget.hlsState == "HLS_STOPPING" ||
              widget.hlsState == "HLS_STARTED")
            HLSIndicator(hlsState: widget.hlsState),
          if (widget.hlsState == "HLS_STARTING" ||
              widget.hlsState == "HLS_STOPPING" ||
              widget.hlsState == "HLS_STARTED")
            const HorizontalSpacer(),
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.meeting.id,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.meeting.id));
                    showSnackBarMessage(
                        message: "Meeting ID has been copied.",
                        context: context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
