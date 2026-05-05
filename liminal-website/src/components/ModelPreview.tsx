"use client";

import { Suspense, useRef } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls, PerspectiveCamera, Environment, useGLTF } from "@react-three/drei";
import * as THREE from "three";

function Model({ url }: { url: string }) {
  const { scene } = useGLTF(url);
  const ref = useRef<THREE.Group>(null);

  return (
    <group ref={ref}>
      <primitive object={scene} />
    </group>
  );
}

function LoadingFallback() {
  return (
    <mesh>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="#1a1a1a" wireframe />
    </mesh>
  );
}

function ErrorFallback() {
  return (
    <group>
      {/* Placeholder shape */}
      <mesh>
        <icosahedronGeometry args={[0.8, 1]} />
        <meshStandardMaterial color="#1a1a1a" wireframe />
      </mesh>
      <mesh>
        <ringGeometry args={[1, 1.05, 64]} />
        <meshBasicMaterial color="#c4a35a" side={THREE.DoubleSide} transparent opacity={0.3} />
      </mesh>
    </group>
  );
}

interface ModelPreviewProps {
  modelUrl?: string;
  className?: string;
}

function ModelPreviewInner({ modelUrl, className }: ModelPreviewProps) {
  return (
    <div className={`relative aspect-square bg-[#0a0a0a] border border-white/[0.04] overflow-hidden ${className ?? ""}`}>
      <Canvas
        gl={{ antialias: true, alpha: false }}
        style={{ background: "#0a0a0a" }}
      >
        <PerspectiveCamera makeDefault position={[0, 0.5, 4]} fov={40} />
        <Environment preset="studio" />
        <ambientLight intensity={0.4} />
        <directionalLight position={[5, 5, 5]} intensity={0.8} />
        <directionalLight position={[-3, 2, -2]} intensity={0.3} color="#c4a35a" />

        <Suspense fallback={<LoadingFallback />}>
          {modelUrl ? <Model url={modelUrl} /> : <ErrorFallback />}
        </Suspense>

        <OrbitControls
          enableZoom
          enablePan={false}
          autoRotate
          autoRotateSpeed={1.2}
          minDistance={2.5}
          maxDistance={8}
          maxPolarAngle={Math.PI * 0.7}
        />
      </Canvas>

      {/* Corner accents */}
      <div className="absolute top-0 left-0 w-4 h-4 border-t border-l border-[#c4a35a]/20 pointer-events-none" />
      <div className="absolute top-0 right-0 w-4 h-4 border-t border-r border-[#c4a35a]/20 pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-4 h-4 border-b border-l border-[#c4a35a]/20 pointer-events-none" />
      <div className="absolute bottom-0 right-0 w-4 h-4 border-b border-r border-[#c4a35a]/20 pointer-events-none" />

      {!modelUrl && (
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <span className="terminal-text text-[10px] text-[#4a4a4a] tracking-[0.15em]">
            [ MODEL UNAVAILABLE ]
          </span>
        </div>
      )}
    </div>
  );
}

export default function ModelPreview(props: ModelPreviewProps) {
  return (
    <Suspense
      fallback={
        <div className={`aspect-square bg-[#0a0a0a] border border-white/[0.04] flex items-center justify-center ${props.className ?? ""}`}>
          <span className="terminal-text text-[10px] text-[#4a4a4a]">LOADING...</span>
        </div>
      }
    >
      <ModelPreviewInner {...props} />
    </Suspense>
  );
}
