import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt/state/MQTTAppState.dart';
import '../mqtt/MQTTManager.dart';

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  late MQTTAppState currentAppState;
  late MQTTManager manager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);

    currentAppState = appState;
    final Scaffold scaffold = Scaffold(
      body: _buildColumn(),
      appBar: AppBar(
        title: const Text('MQTT'),
        backgroundColor: Colors.greenAccent,
      ),
    );
    return SafeArea(child: scaffold);
  }

  Widget _buildColumn() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildConnectionStateText(
              _prepareStateMessageFrom(currentAppState.getAppConnectionState)),
          _buildEditableColumn(),
          _buildScrollableTextWith(currentAppState.getHistoryText)
        ],
      ),
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Enter broker address',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildTextFieldWith(
              _topicTextController,
              'Enter a topic to subscribe or listen',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildPublishMessageRow(),
          const SizedBox(height: 10),
          _buildConnectButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController, 'Enter a message',
              currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Container(
              height: 30,
              color: Colors.deepOrangeAccent,
              child: Center(child: Text(status, textAlign: TextAlign.center))),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController &&
        state == MQTTAppConnectionState.connected) {
      shouldEnable = true;
    } else if ((controller == _hostTextController &&
            state == MQTTAppConnectionState.disconnected) ||
        (controller == _topicTextController &&
            state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: 400,
        height: 200,
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildConnectButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          // ignore: deprecated_member_use
          child: RaisedButton(
            color: Colors.lightBlueAccent,
            child: const Text('Connect'),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? _configureAndConnect
                : null, //
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ignore: deprecated_member_use
          child: RaisedButton(
            color: Colors.redAccent,
            child: const Text('Disconnect'),
            onPressed: state == MQTTAppConnectionState.connected
                ? _disconnect
                : null, //
          ),
        ),
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    // ignore: deprecated_member_use
    return RaisedButton(
      color: Colors.green,
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  
  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Connected';
      case MQTTAppConnectionState.connecting:
        return 'Connecting';
      case MQTTAppConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  void _configureAndConnect() {
    String deviceId = DateTime.now().toString();
    manager = MQTTManager(
        host: _hostTextController.text,
        topic: _topicTextController.text,
        identifier: deviceId,
        state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _disconnect() {
    manager.disconnect();
  }

  void _publishMessage(String text) {
    final String message = text;
    manager.publish(message);
    _messageTextController.clear();
  }
}
