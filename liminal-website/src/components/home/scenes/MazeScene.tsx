"use client";

import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";
import { useScene } from "../AtmosphericCanvas";

const GRID_SIZE = 5;
const CELL_SIZE = 0.8;

function GridBox({ x, z, delay }: { x: number; z: number; delay: number }) {
  const ref = useRef<THREE.Mesh>(null);
  const { progress } = useScene();

  useFrame(() => {
    if (!ref.current) return;
    const emerge = Math.max(0, Math.min(1, (progress - delay) * 3));
    ref.current.scale.setScalar(emerge);
    (ref.current.material as THREE.MeshBasicMaterial).opacity = 0.08 + emerge * 0.22;
  });

  const offsetX = (x - (GRID_SIZE - 1) / 2) * CELL_SIZE;
  const offsetZ = (z - (GRID_SIZE - 1) / 2) * CELL_SIZE;

  return (
    <mesh ref={ref} position={[offsetX, 0, offsetZ]} scale={[0, 0, 0]}>
      <boxGeometry args={[CELL_SIZE * 0.85, CELL_SIZE * 0.85, CELL_SIZE * 0.85]} />
      <meshBasicMaterial color="#c4a35a" wireframe transparent opacity={0.08} />
    </mesh>
  );
}

function CenterTower() {
  const ref = useRef<THREE.Mesh>(null);
  const { progress } = useScene();

  useFrame((_, delta) => {
    if (!ref.current) return;
    ref.current.rotation.y += delta * 0.3;
    ref.current.rotation.x += delta * 0.1;
    const scale = Math.max(0, Math.min(1, (progress - 0.3) * 2));
    ref.current.scale.setScalar(0.5 + scale * 1.5);
    (ref.current.material as THREE.MeshBasicMaterial).opacity = 0.15 + scale * 0.5;
  });

  return (
    <mesh ref={ref} scale={[0.5, 0.5, 0.5]}>
      <boxGeometry args={[1.2, 2.5, 1.2]} />
      <meshBasicMaterial color="#c4a35a" wireframe transparent opacity={0.15} />
    </mesh>
  );
}

function GuideLine() {
  const groupRef = useRef<THREE.Group>(null);
  const matRef = useRef<THREE.LineBasicMaterial>(null);
  const { progress } = useScene();

  const points = useMemo(() => {
    const pts: THREE.Vector3[] = [];
    const segments = 40;
    for (let i = 0; i <= segments; i++) {
      const t = i / segments;
      const angle = t * Math.PI * 4;
      const radius = 2.5 - t * 2;
      pts.push(new THREE.Vector3(
        Math.cos(angle) * radius,
        -1 + t * 2,
        Math.sin(angle) * radius,
      ));
    }
    return pts;
  }, []);

  useFrame(() => {
    if (!matRef.current) return;
    matRef.current.opacity = 0.2 + progress * 0.5;
  });

  const lineGeometry = useMemo(() => {
    const geo = new THREE.BufferGeometry();
    geo.setAttribute("position", new THREE.Float32BufferAttribute(
      points.flatMap((p) => [p.x, p.y, p.z]), 3,
    ));
    return geo;
  }, [points]);

  return (
    <group ref={groupRef}>
      <primitive object={new THREE.Line(lineGeometry, new THREE.LineBasicMaterial({ color: "#c4a35a", transparent: true, opacity: 0.2 }))} />
    </group>
  );
}

export default function MazeScene() {
  const groupRef = useRef<THREE.Group>(null);

  const gridBoxes = useMemo(() => {
    const boxes: { x: number; z: number; delay: number }[] = [];
    for (let x = 0; x < GRID_SIZE; x++) {
      for (let z = 0; z < GRID_SIZE; z++) {
        boxes.push({ x, z, delay: (x + z) / (GRID_SIZE * 2) });
      }
    }
    return boxes;
  }, []);

  useFrame((_, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y += delta * 0.08;
    }
  });

  return (
    <>
      <ambientLight intensity={0.15} />
      <pointLight position={[0, 1, 0]} intensity={0.3} color="#c4a35a" distance={6} />
      <group ref={groupRef}>
        {gridBoxes.map((b) => (
          <GridBox key={`${b.x}-${b.z}`} x={b.x} z={b.z} delay={b.delay} />
        ))}
        <CenterTower />
        <GuideLine />
      </group>
    </>
  );
}
