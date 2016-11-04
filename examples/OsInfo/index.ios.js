/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';
import os from 'os';

export default class OsInfo extends Component {
  constructor(props) {
    super(props);

    this.state = { networkInterfaces: JSON.stringify(os.networkInterfaces()) };
  }

  componentDidMount() {
    setTimeout(() => {
      this.setState({
        networkInterfaces: JSON.stringify(os.networkInterfaces())
      });
    }, 6000);
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          {this.state.networkInterfaces}
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('OsInfo', () => OsInfo);
