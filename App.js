import React, { useState, useEffect, useRef } from 'react';
import { 
  StyleSheet, 
  View, 
  Text, 
  TouchableOpacity, 
  SafeAreaView, 
  Dimensions, 
  ScrollView, 
  Modal,
  Image,
  Animated,
  StatusBar
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { 
  Shield, 
  Crown, 
  Zap, 
  Globe, 
  Power, 
  Menu, 
  ChevronRight, 
  Lock,
  Users,
  Briefcase,
  Activity
} from 'lucide-react-native';
import { MotiView } from 'moti';

const { width, height } = Dimensions.get('window');

/**
 * Btaf Meet - Main Application Entry Point (Expo Version)
 * This file implements the premium UI design and VPN logic using React Native.
 */
export default function App() {
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [showSystemDialog, setShowSystemDialog] = useState(false);
  const [selectedServer, setSelectedServer] = useState({
    name: 'Global Network',
    country: 'Auto',
    flag: '🌍',
    id: 'auto'
  });

  // Simulated Stats
  const [ping, setPing] = useState(0);
  const [activeUsers, setActiveUsers] = useState('1.2K');

  useEffect(() => {
    if (isConnected) {
      const interval = setInterval(() => {
        setPing(Math.floor(Math.random() * 20) + 15);
      }, 2000);
      return () => clearInterval(interval);
    } else {
      setPing(0);
    }
  }, [isConnected]);

  const handleConnect = () => {
    if (isConnected) {
      setIsConnected(false);
      return;
    }
    setShowSystemDialog(true);
  };

  const confirmConnection = () => {
    setShowSystemDialog(false);
    setIsConnecting(true);
    setTimeout(() => {
      setIsConnecting(false);
      setIsConnected(true);
    }, 2000);
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      <LinearGradient
        colors={['#005F8A', '#003D5B']}
        style={styles.background}
      />

      <SafeAreaView style={styles.safeArea}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity style={styles.iconButton}>
            <Menu color="white" size={24} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Btaf Meet</Text>
          <TouchableOpacity style={styles.iconButton}>
            <Crown color="#FFD700" size={24} />
          </TouchableOpacity>
        </View>

        {/* Stats Section */}
        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Users color="rgba(255,255,255,0.7)" size={20} />
            <Text style={styles.statValue}>{activeUsers}</Text>
            <Text style={styles.statLabel}>Active Users</Text>
          </View>
          <View style={styles.statItem}>
            <Briefcase color="rgba(255,255,255,0.7)" size={20} />
            <Text style={styles.statValue}>450+</Text>
            <Text style={styles.statLabel}>Jobs Available</Text>
          </View>
          <View style={styles.statItem}>
            <Activity color="rgba(255,255,255,0.7)" size={20} />
            <Text style={styles.statValue}>{ping > 0 ? `${ping}ms` : '--'}</Text>
            <Text style={styles.statLabel}>Latency</Text>
          </View>
        </View>

        {/* Main Connect Button Area */}
        <View style={styles.centerArea}>
          <TouchableOpacity 
            activeOpacity={0.8}
            onPress={handleConnect}
            disabled={isConnecting}
          >
            <View style={styles.outerCircle}>
              {isConnected && (
                <MotiView
                  from={{ scale: 1, opacity: 0.3 }}
                  animate={{ scale: 1.5, opacity: 0 }}
                  transition={{ loop: true, duration: 2000, type: 'timing' }}
                  style={[styles.pulseCircle, { backgroundColor: '#4CAF50' }]}
                />
              )}
              <View style={[styles.innerCircle, { backgroundColor: isConnected ? '#4CAF50' : 'white' }]}>
                <Power color={isConnected ? 'white' : '#005F8A'} size={64} />
              </View>
            </View>
          </TouchableOpacity>
          <Text style={styles.statusText}>
            {isConnecting ? 'SEARCHING...' : (isConnected ? 'MEETING ACTIVE' : 'START MEETING')}
          </Text>
        </View>

        {/* Server Selector */}
        <TouchableOpacity style={styles.serverSelector}>
          <Text style={styles.flagText}>{selectedServer.flag}</Text>
          <View style={styles.serverInfo}>
            <Text style={styles.serverName}>{selectedServer.name}</Text>
            <Text style={styles.serverCountry}>{selectedServer.country}</Text>
          </View>
          <ChevronRight color="white" size={24} />
        </TouchableOpacity>
      </SafeAreaView>

      {/* Simulated Android VPN Permission Dialog */}
      <Modal
        visible={showSystemDialog}
        transparent={true}
        animationType="fade"
      >
        <View style={styles.modalOverlay}>
          <View style={styles.systemDialog}>
            <View style={styles.dialogHeader}>
              <View style={styles.shieldIcon}>
                <Shield color="#005F8A" size={20} />
              </View>
              <Text style={styles.dialogTitle}>Connection Request</Text>
            </View>
            <Text style={styles.dialogContent}>
              Btaf Meet wants to set up a VPN connection that allows it to monitor network traffic. Only accept if you trust the source.
              {"\n\n"}
              <Text style={styles.boldText}>App: Btaf Meet</Text>
            </Text>
            <View style={styles.dialogActions}>
              <TouchableOpacity onPress={() => setShowSystemDialog(false)}>
                <Text style={styles.cancelButton}>CANCEL</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={confirmConnection}>
                <Text style={styles.okButton}>OK</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  background: {
    ...StyleSheet.absoluteFillObject,
  },
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 10,
  },
  headerTitle: {
    color: 'white',
    fontSize: 20,
    fontWeight: '900',
    letterSpacing: -0.5,
  },
  iconButton: {
    padding: 8,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 30,
    paddingHorizontal: 20,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
    marginTop: 4,
  },
  statLabel: {
    color: 'rgba(255,255,255,0.5)',
    fontSize: 10,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  centerArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  outerCircle: {
    width: 220,
    height: 220,
    borderRadius: 110,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  innerCircle: {
    width: 170,
    height: 170,
    borderRadius: 85,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 10,
  },
  pulseCircle: {
    position: 'absolute',
    width: 170,
    height: 170,
    borderRadius: 85,
  },
  statusText: {
    color: 'white',
    fontSize: 18,
    fontWeight: '900',
    letterSpacing: 3,
    marginTop: 40,
  },
  serverSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.1)',
    margin: 24,
    padding: 16,
    borderRadius: 24,
  },
  flagText: {
    fontSize: 32,
  },
  serverInfo: {
    flex: 1,
    marginLeft: 16,
  },
  serverName: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
  serverCountry: {
    color: 'rgba(255,255,255,0.6)',
    fontSize: 12,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  systemDialog: {
    width: '100%',
    backgroundColor: 'white',
    borderRadius: 20,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.25,
    shadowRadius: 20,
    elevation: 20,
  },
  dialogHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  shieldIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#E3F2FD',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  dialogTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  dialogContent: {
    fontSize: 14,
    color: '#666',
    lineHeight: 20,
    marginBottom: 24,
  },
  boldText: {
    fontWeight: 'bold',
    color: '#333',
  },
  dialogActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  cancelButton: {
    color: '#888',
    fontWeight: 'bold',
    marginRight: 24,
  },
  okButton: {
    color: '#005F8A',
    fontWeight: 'bold',
    fontSize: 16,
  }
});
