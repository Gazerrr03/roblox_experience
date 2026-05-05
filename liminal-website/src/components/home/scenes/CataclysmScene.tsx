"use client";

import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { useScene } from "../AtmosphericCanvas";

function Shard({ index }: { index: number }) {
  const ref = useRef<THREE.Mesh>(null);
  const speed = 0.1 + index * 0.08;
  const startY = 3 + index * 1.5;
  const rotAxis = useMemo(
    () => new THREE.Vector3(Math.random(), Math.random(), Math.random()).normalize(),
    [],
  );

  useFrame((_, delta) => {
    if (!ref.current) return;
    ref.current.rotation.x += delta * speed * 0.3;
    ref.current.rotation.y += delta * speed * 0.5;
    ref.current.position.y -= delta * speed * 0.6;
    if (ref.current.position.y < -5) ref.current.position.y = startY;
  });

  return (
    <mesh ref={ref} position={[(Math.random() - 0.5) * 8, startY, (Math.random() - 0.5) * 6]}>
      <icosahedronGeometry args={[0.3 + index * 0.15, 0]} />
      <meshBasicMaterial color="#c4a35a" wireframe transparent opacity={0.2} />
    </mesh>
  );
}

export default function CataclysmScene() {
  const { progress, isMobile } = useScene();
  const pointsRef = useRef<THREE.Points>(null);
  const groupRef = useRef<THREE.Group>(null);

  const count = isMobile ? 120 : 250;
  const shardCount = isMobile ? 4 : 7;

  const { positions, colors } = useMemo(() => {
    const pos = new Float32Array(count * 3);
    const col = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const radius = 2 + Math.random() * 3;
      pos[i * 3] = Math.cos(angle) * radius;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 4;
      pos[i * 3 + 2] = Math.sin(angle) * radius;

      const t = Math.random();
      const r = 0.55 + t * 0.25;
      const g = 0.38 + t * 0.25;
      const b = 0.25;
      col[i * 3] = r;
      col[i * 3 + 1] = g;
      col[i * 3 + 2] = b;
    }
    return { positions: pos, colors: col };
  }, [count]);

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.15 * (1 + progress);
    }
    if (pointsRef.current) {
      const mat = pointsRef.current.material as THREE.PointsMaterial;
      mat.color.lerp(
        new THREE.Color().setRGB(
          0.55 + progress * 0.45,
          0.38 - progress * 0.2,
          0.25 - progress * 0.15,
        ),
        delta,
      );
    }
  });

  return (
    <>
      <ambientLight intensity={0.12} />
      <directionalLight
        position={[5, 2, -3]}
        intensity={0.3 + progress * 0.3}
        color={progress > 0.5 ? "#8b1a1a" : "#c4a35a"}
      />
      <group ref={groupRef}>
        <points ref={pointsRef}>
          <bufferGeometry>
            <bufferAttribute
              attach="attributes-position"
              args={[positions, 3]}
            />
            <bufferAttribute attach="attributes-color" args={[colors, 3]} />
          </bufferGeometry>
          <pointsMaterial
            size={0.04}
            vertexColors
            transparent
            opacity={0.5}
            blending={THREE.AdditiveBlending}
            depthWrite={false}
          />
        </points>
        {Array.from({ length: shardCount }).map((_, i) => (
          <Shard key={i} index={i} />
        ))}
      </group>
    </>
  );
}
