"use client";

import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { useScene } from "../AtmosphericCanvas";

export default function DarknessScene() {
  const { progress, isMobile } = useScene();
  const pointsRef = useRef<THREE.Points>(null);

  const count = isMobile ? 50 : 100;
  const { positions, colors } = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const col = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 6;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 8;
      pos[i * 3 + 2] = (Math.random() - 0.5) * 6;
      const amber = Math.random() * 0.4 + 0.1;
      col[i * 3] = amber * 0.77; // r
      col[i * 3 + 1] = amber * 0.64; // g
      col[i * 3 + 2] = amber * 0.35; // b
    }
    return { positions: pos, colors: col };
  }, [count]);

  useFrame((_, delta) => {
    if (!pointsRef.current) return;
    const posAttr = pointsRef.current.geometry.attributes
      .position as THREE.BufferAttribute;
    const arr = posAttr.array as Float32Array;
    for (let i = 0; i < count; i++) {
      arr[i * 3 + 1] += delta * 0.15 * (0.5 + progress * 0.5);
      if (arr[i * 3 + 1] > 4) arr[i * 3 + 1] = -4;
    }
    posAttr.needsUpdate = true;
    const mat = pointsRef.current.material as THREE.PointsMaterial;
    mat.opacity = 0.2 + progress * 0.8;
  });

  return (
    <>
      <ambientLight intensity={0.08} />
      <pointLight
        position={[0, 0, 2]}
        intensity={0.2 + progress * 0.4}
        color="#c4a35a"
        distance={8}
      />
      <points ref={pointsRef}>
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            args={[positions, 3]}
          />
          <bufferAttribute attach="attributes-color" args={[colors, 3]} />
        </bufferGeometry>
        <pointsMaterial
          size={0.03}
          vertexColors
          transparent
          opacity={0.2}
          blending={THREE.AdditiveBlending}
          depthWrite={false}
        />
      </points>
    </>
  );
}
