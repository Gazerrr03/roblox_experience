"use client";

import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { useScene } from "../AtmosphericCanvas";

interface PageData {
  angle: number;
  radius: number;
  height: number;
  tilt: number;
  delay: number;
}

function Pages() {
  const groupRef = useRef<THREE.Group>(null);
  const { progress } = useScene();
  const pageCount = 70;

  const pages = useMemo(() => {
    const data: PageData[] = [];
    for (let i = 0; i < pageCount; i++) {
      data.push({
        angle: Math.random() * Math.PI * 2,
        radius: 1.5 + Math.random() * 2.5,
        height: (Math.random() - 0.5) * 3,
        tilt: (Math.random() - 0.5) * Math.PI * 0.6,
        delay: i / pageCount * 0.4,
      });
    }
    return data;
  }, []);

  const meshes = useMemo(() => {
    return pages.map((p) => {
      const meshRef = { current: null as THREE.Mesh | null };
      return { p, ref: meshRef };
    });
  }, [pages]);

  useFrame((_, delta) => {
    if (!groupRef.current) return;
    groupRef.current.rotation.y += delta * 0.05;

    meshes.forEach(({ p, ref }) => {
      if (!ref.current) return;
      const phase = Math.max(0, Math.min(1, (progress - p.delay) * 2.5));

      const targetRadius = 1.5 + p.radius * (1 - phase);
      const targetAngle = p.angle + phase * 2;
      const targetHeight = p.height * (1 - phase);
      const targetX = Math.cos(targetAngle) * targetRadius;
      const targetZ = Math.sin(targetAngle) * targetRadius;

      ref.current.position.lerp(new THREE.Vector3(targetX, targetHeight, targetZ), delta * 0.8);
      ref.current.rotation.x += delta * 0.1 * (1 - phase);
      ref.current.rotation.z = THREE.MathUtils.lerp(ref.current.rotation.z, p.tilt * (1 - phase), delta * 0.5);
      (ref.current.material as THREE.MeshBasicMaterial).opacity = 0.05 + phase * 0.45;
      ref.current.scale.setScalar(0.7 + phase * 0.3);
    });
  });

  return (
    <group ref={groupRef}>
      {meshes.map(({ p, ref }, i) => (
        <mesh
          key={i}
          ref={(el) => { ref.current = el; }}
          position={[
            Math.cos(p.angle) * p.radius,
            p.height,
            Math.sin(p.angle) * p.radius,
          ]}
        >
          <planeGeometry args={[0.2, 0.3]} />
          <meshBasicMaterial color="#c4a35a" side={THREE.DoubleSide} transparent opacity={0.05} />
        </mesh>
      ))}
    </group>
  );
}

function QuestionMarkParticles() {
  const pointsRef = useRef<THREE.Points>(null);
  const { progress, isMobile } = useScene();
  const count = isMobile ? 80 : 150;

  const basePositions = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const qmCoords: [number, number][] = [
      [0, 1.2], [0.15, 1.35], [0.35, 1.45], [0.55, 1.4], [0.68, 1.25],
      [0.72, 1.05], [0.68, 0.85], [0.55, 0.7], [0.35, 0.6], [0.15, 0.6],
      [0, 0.65],
      [0.2, -0.15], [0.3, -0.25], [0.4, -0.2], [0.35, -0.05], [0.2, 0],
    ];
    const centers: [number, number, number][] = qmCoords.map(
      ([y, z]) => [0, y * 0.9, z * 0.9] as [number, number, number],
    );

    for (let i = 0; i < count; i++) {
      const center = centers[i % centers.length];
      pos[i * 3] = center[0] + (Math.random() - 0.5) * 0.25;
      pos[i * 3 + 1] = center[1] + (Math.random() - 0.5) * 0.25;
      pos[i * 3 + 2] = center[2] + (Math.random() - 0.5) * 0.25;
    }
    return pos;
  }, [count]);

  const scatterPositions = useMemo(() => {
    const pos = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const radius = 0.8 + Math.random() * 2.5;
      pos[i * 3] = Math.cos(angle) * radius;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 3;
      pos[i * 3 + 2] = Math.sin(angle) * radius;
    }
    return pos;
  }, [count]);

  useFrame(() => {
    if (!pointsRef.current) return;
    const arr = (pointsRef.current.geometry.attributes.position as THREE.BufferAttribute).array as Float32Array;
    const t = progress;
    const eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

    for (let i = 0; i < count; i++) {
      arr[i * 3] = THREE.MathUtils.lerp(basePositions[i * 3], scatterPositions[i * 3], 1 - eased);
      arr[i * 3 + 1] = THREE.MathUtils.lerp(basePositions[i * 3 + 1], scatterPositions[i * 3 + 1], 1 - eased);
      arr[i * 3 + 2] = THREE.MathUtils.lerp(basePositions[i * 3 + 2], scatterPositions[i * 3 + 2], 1 - eased);
    }
    pointsRef.current.geometry.attributes.position.needsUpdate = true;
    (pointsRef.current.material as THREE.PointsMaterial).opacity = 0.15 + eased * 0.55;
  });

  return (
    <points ref={pointsRef}>
      <bufferGeometry>
        <bufferAttribute attach="attributes-position" args={[scatterPositions, 3]} />
      </bufferGeometry>
      <pointsMaterial
        size={0.04}
        color="#c4a35a"
        transparent
        opacity={0.15}
        blending={THREE.AdditiveBlending}
        depthWrite={false}
      />
    </points>
  );
}

export default function QuestionScene() {
  const { progress } = useScene();

  return (
    <>
      <ambientLight intensity={0.1 + progress * 0.08} />
      <pointLight position={[0, 0, 2]} intensity={0.25} color="#c4a35a" distance={8} />
      <Pages />
      <QuestionMarkParticles />
    </>
  );
}
