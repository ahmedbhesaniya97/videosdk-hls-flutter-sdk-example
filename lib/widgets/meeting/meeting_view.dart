import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_hls_flutter_example/constants/colors.dart';
import 'package:videosdk_hls_flutter_example/utils/toast.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/participant/participant_list.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/meeting_controls/meeting_action_bar.dart';
import 'package:videosdk_hls_flutter_example/widgets/meeting/participant_grid.dart';
import 'package:videosdk_hls_flutter_example/widgets/meeting/screenshare_view.dart';

import 'package:videosdk_hls_flutter_example/widgets/common/app_bar/meeting_appbar.dart';
import 'package:videosdk_hls_flutter_example/widgets/common/chat/chat_view.dart';

class MeetingView extends StatefulWidget {
  final Room meeting;
  final String token;
  const MeetingView({super.key, required this.meeting, required this.token});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  bool showChatSnackbar = true;
  String recordingState = "RECORDING_STOPPED";
  String hlsState = "HLS_STOPPED";

  // Streams
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  Stream? remoteParticipantShareStream;

  bool fullScreen = false;

  @override
  void initState() {
    super.initState();
    // Register meeting events
    recordingState = widget.meeting.recordingState;
    hlsState = widget.meeting.hlsState;

    registerMeetingEvents(widget.meeting);
    subscribeToChatMessages(widget.meeting);
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          MeetingAppBar(
            meeting: widget.meeting,
            token: widget.token,
            recordingState: recordingState,
            hlsState: hlsState,
            isFullScreen: fullScreen,
          ),
          Expanded(
            child: GestureDetector(
                onDoubleTap: () => {
                      setState(() {
                        fullScreen = !fullScreen;
                      })
                    },
                child: OrientationBuilder(builder: (context, orientation) {
                  return Flex(
                    direction: orientation == Orientation.portrait
                        ? Axis.vertical
                        : Axis.horizontal,
                    children: [
                      ScreenShareView(meeting: widget.meeting),
                      Flexible(
                          child: ParticipantGrid(
                              meeting: widget.meeting,
                              orientation: orientation))
                    ],
                  );
                })),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: !fullScreen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: MeetingActionBar(
              isMicEnabled: audioStream != null,
              isCamEnabled: videoStream != null,
              isScreenShareEnabled: shareStream != null,
              recordingState: recordingState,
              hlsState: hlsState,
              // Called when Call End button is pressed
              onCallEndButtonPressed: () {
                widget.meeting.end();
              },

              onCallLeaveButtonPressed: () {
                widget.meeting.leave();
              },
              // Called when mic button is pressed
              onMicButtonPressed: () {
                if (audioStream != null) {
                  widget.meeting.muteMic();
                } else {
                  widget.meeting.unmuteMic();
                }
              },
              // Called when camera button is pressed
              onCameraButtonPressed: () {
                if (videoStream != null) {
                  widget.meeting.disableCam();
                } else {
                  widget.meeting.enableCam();
                }
              },

              onSwitchMicButtonPressed: (details) async {
                List<MediaDeviceInfo> outptuDevice =
                    widget.meeting.getAudioOutputDevices();
                double bottomMargin = (70.0 * outptuDevice.length);
                final screenSize = MediaQuery.of(context).size;
                await showMenu(
                  context: context,
                  color: black700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  position: RelativeRect.fromLTRB(
                    screenSize.width - details.globalPosition.dx,
                    details.globalPosition.dy - bottomMargin,
                    details.globalPosition.dx,
                    (bottomMargin),
                  ),
                  items: outptuDevice.map((e) {
                    return PopupMenuItem(value: e, child: Text(e.label));
                  }).toList(),
                  elevation: 8.0,
                ).then((value) {
                  if (value != null) {
                    widget.meeting.switchAudioDevice(value);
                  }
                });
              },

              onSwitchCameraButtonPressed: (details) async {
                List<MediaDeviceInfo> outptuDevice =
                    widget.meeting.getCameras();
                double bottomMargin = (70.0 * outptuDevice.length);
                final screenSize = MediaQuery.of(context).size;
                await showMenu(
                  context: context,
                  color: black700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  position: RelativeRect.fromLTRB(
                    screenSize.width - details.globalPosition.dx,
                    details.globalPosition.dy - bottomMargin,
                    details.globalPosition.dx,
                    (bottomMargin),
                  ),
                  items: outptuDevice.map((e) {
                    return PopupMenuItem(value: e, child: Text(e.label));
                  }).toList(),
                  elevation: 8.0,
                ).then((value) {
                  if (value != null) {
                    widget.meeting.changeCam(value.deviceId);
                  }
                });
              },

              onChatButtonPressed: () {
                setState(() {
                  showChatSnackbar = false;
                });
                showModalBottomSheet(
                  context: context,
                  constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height - statusbarHeight),
                  isScrollControlled: true,
                  builder: (context) => ChatView(
                    key: const Key("ChatScreen"),
                    meeting: widget.meeting,
                    showClose: true,
                    orientation: Orientation.portrait,
                    onClose: () {
                      Navigator.pop(context);
                    },
                  ),
                ).whenComplete(() => {
                      setState(() {
                        showChatSnackbar = true;
                      })
                    });
              },

              // Called when more options button is pressed
              onMoreOptionSelected: (option) {
                // Showing more options dialog box
                if (option == "screenshare") {
                  if (remoteParticipantShareStream == null) {
                    if (shareStream == null) {
                      widget.meeting.enableScreenShare();
                    } else {
                      widget.meeting.disableScreenShare();
                    }
                  } else {
                    showSnackBarMessage(
                        message: "Someone is already presenting",
                        context: context);
                  }
                } else if (option == "recording") {
                  if (recordingState == "RECORDING_STOPPING") {
                    showSnackBarMessage(
                        message: "Recording is in stopping state",
                        context: context);
                  } else if (recordingState == "RECORDING_STARTED") {
                    widget.meeting.stopRecording();
                  } else if (recordingState == "RECORDING_STARTING") {
                    showSnackBarMessage(
                        message: "Recording is in starting state",
                        context: context);
                  } else {
                    widget.meeting.startRecording();
                  }
                } else if (option == "participants") {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: false,
                    builder: (context) =>
                        ParticipantList(meeting: widget.meeting),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when recording is started
    _meeting.on(Events.recordingStateChanged, (String status) {
      if (mounted) {
        showSnackBarMessage(
            message:
                "Meeting recording ${status == "RECORDING_STARTING" ? "is starting" : status == "RECORDING_STARTED" ? "started" : status == "RECORDING_STOPPING" ? "is stopping" : "stopped"}",
            context: context);
      }
      setState(() {
        recordingState = status;
      });
    });

    // Called when hls is started
    _meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      if (mounted) {
        showSnackBarMessage(
            message:
                "Meeting HLS ${data['status'] == "HLS_STARTING" ? "is starting" : data['status'] == "HLS_STARTED" ? "started" : data['status'] == "HLS_STOPPING" ? "is stopping" : "stopped"}",
            context: context);
      }
      setState(() {
        hlsState = data['status'];
      });
    });

    // Called when stream is enabled
    _meeting.localParticipant.on(Events.streamEnabled, (Stream _stream) {
      if (_stream.kind == 'video') {
        setState(() {
          videoStream = _stream;
        });
      } else if (_stream.kind == 'audio') {
        setState(() {
          audioStream = _stream;
        });
      } else if (_stream.kind == 'share') {
        setState(() {
          shareStream = _stream;
        });
      }
    });

    // Called when stream is disabled
    _meeting.localParticipant.on(Events.streamDisabled, (Stream _stream) {
      if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
        setState(() {
          videoStream = null;
        });
      } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
        setState(() {
          audioStream = null;
        });
      } else if (_stream.kind == 'share' && shareStream?.id == _stream.id) {
        setState(() {
          shareStream = null;
        });
      }
    });

    // Called when presenter is changed
    _meeting.on(Events.presenterChanged, (_activePresenterId) {
      Participant? activePresenterParticipant =
          _meeting.participants[_activePresenterId];

      // Get Share Stream
      Stream? _stream = activePresenterParticipant?.streams.values
          .singleWhere((e) => e.kind == "share");

      setState(() => remoteParticipantShareStream = _stream);
    });

    _meeting.on(
        Events.error,
        (error) => {
              if (mounted)
                {
                  showSnackBarMessage(
                      message: error['name'].toString() +
                          " :: " +
                          error['message'].toString(),
                      context: context)
                }
            });
  }

  void subscribeToChatMessages(Room meeting) {
    meeting.pubSub.subscribe("CHAT", (message) {
      if (message.senderId != meeting.localParticipant.id) {
        if (mounted) {
          if (showChatSnackbar) {
            showSnackBarMessage(
                message: message.senderName + ": " + message.message,
                context: context);
          }
        }
      }
    });

    meeting.pubSub.subscribe("RAISE_HAND", (message) {
      if (message.senderId != meeting.localParticipant.id) {
        if (mounted) {
          if (showChatSnackbar) {
            showSnackBarMessage(
                icon: SvgPicture.asset(
                  "assets/ic_hand.svg",
                  color: Colors.black,
                ),
                message: message.senderName + " raised hand ",
                context: context);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
