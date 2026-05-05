"use client";

import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { useScene } from "../AtmosphericCanvas";

function EyeForm() {
  const groupRef = useRef<THREE.Group>(null);
  const irisRef = useRef<THREE.Mesh>(null);
  const { progress } = useScene();

  const emerge = useMemo(() => Math.max(0, Math.min(1, (progress - 0.05) * 3)), [progress]);

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.15;
      const scale = emerge;
      groupRef.current.scale.setScalar(0.6 + scale * 0.4);
    }
    if (irisRef.current) {
      irisRef.current.rotation.z += delta * 0.4;
      irisRef.current.scale.setScalar(0.7 + Math.sin(Date.now() * 0.002) * 0.15);
    }
  });

  return (
    <group ref={groupRef} position={[-2.2, 0, 0]}>
      <mesh>
        <sphereGeometry args={[0.5, 48, 48]} />
        <meshBasicMaterial color="#8b1a1a" wireframe transparent opacity={0.25} />
      </mesh>
      <mesh ref={irisRef}>
        <ringGeometry args={[0.15, 0.25, 64]} />
        <meshBasicMaterial color="#c0392b" side={THREE.DoubleSide} transparent opacity={0.5} />
      </mesh>
    </group>
  );
}

function EarForm() {
  const groupRef = useRef<THREE.Group>(null);
  const innerRingRef = useRef<THREE.Mesh>(null);
  const { progress } = useScene();

  const emerge = useMemo(() => Math.max(0, Math.min(1, (progress - 0.15) * 3)), [progress]);

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.x += delta * 0.12;
      groupRef.current.scale.setScalar(0.6 + emerge * 0.4);
    }
    if (innerRingRef.current) {
      innerRingRef.current.rotation.y += delta * 0.35;
      const pulse = 1 + Math.sin(Date.now() * 0.003) * 0.2;
      innerRingRef.current.scale.setScalar(pulse);
    }
  });

  return (
    <group ref={groupRef} position={[0, 0.3, 0]}>
      <mesh>
        <torusGeometry args={[0.5, 0.12, 32, 64]} />
        <meshBasicMaterial color="#8b1a1a" wireframe transparent opacity={0.25} />
      </mesh>
      <mesh ref={innerRingRef}>
        <torusGeometry args={[0.28, 0.06, 24, 48]} />
        <meshBasicMaterial color="#c0392b" wireframe transparent opacity={0.35} />
      </mesh>
    </group>
  );
}

function MouthForm() {
  const groupRef = useRef<THREE.Group>(null);
  const particlesRef = useRef<THREE.Points>(null);
  const { progress } = useScene();

  const emerge = useMemo(() => Math.max(0, Math.min(1, (progress - 0.25) * 3)), [progress]);

  const particlePositions = useMemo(() => {
    const count = 60;
    const pos = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const radius = 0.35 + Math.random() * 0.6;
      pos[i * 3] = Math.cos(angle) * radius;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 1.0;
      pos[i * 3 + 2] = Math.sin(angle) * radius;
    }
    return pos;
  }, []);

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.z += delta * 0.1;
      groupRef.current.scale.setScalar(0.6 + emerge * 0.4);
    }
    if (particlesRef.current) {
      const arr = (particlesRef.current.geometry.attributes.position as THREE.BufferAttribute).array as Float32Array;
      const repulsion = progress * 0.5;
      for (let i = 0; i < 60; i++) {
        const dist = Math.sqrt(arr[i * 3] ** 2 + arr[i * 3 + 1] ** 2 + arr[i * 3 + 2] ** 2);
        if (dist < 0.01) continue;
        const nx = arr[i * 3] / dist;
        const ny = arr[i * 3 + 1] / dist;
        const nz = arr[i * 3 + 2] / dist;
        arr[i * 3] += nx * repulsion * delta * 0.3;
        arr[i * 3 + 1] += ny * repulsion * delta * 0.3;
        arr[i * 3 + 2] += nz * repulsion * delta * 0.3;
        if (Math.abs(arr[i * 3]) > 1.2) arr[i * 3] *= 0.95;
        if (Math.abs(arr[i * 3 + 2]) > 1.2) arr[i * 3 + 2] *= 0.95;
      }
      particlesRef.current.geometry.attributes.position.needsUpdate = true;
      (particlesRef.current.material as THREE.PointsMaterial).opacity = 0.2 + progress * 0.4;
    }
  });

  return (
    <group ref={groupRef} position={[2.2, 0, 0]}>
      <mesh rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[0.28, 0.28, 1.2, 16]} />
        <meshBasicMaterial color="#8b1a1a" wireframe transparent opacity={0.25} />
      </mesh>
      <points ref={particlesRef}>
        <bufferGeometry>
          <bufferAttribute attach="attributes-position" args={[particlePositions, 3]} />
        </bufferGeometry>
        <pointsMaterial
          size={0.03}
          color="#8b1a1a"
          transparent
          opacity={0.2}
          blending={THREE.AdditiveBlending}
          depthWrite={false}
        />
      </points>
    </group>
  );
}

export default function ProhibitionsScene() {
  const groupRef = useRef<THREE.Group>(null);
  const { progress } = useScene();

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.06;
    }
  });

  return (
    <>
      <ambientLight intensity={0.1 + progress * 0.08} />
      <pointLight
        position={[0, 0, 1.5]}
        intensity={0.2 + Math.sin(Date.now() * 0.002) * 0.1}
        color="#8b1a1a"
        distance={5}
      />
      <group ref={groupRef}>
        <EyeForm />
        <EarForm />
        <MouthForm />
      </group>
    </>
  );
}
