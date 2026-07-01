//
//  OrbitMathTests.swift
//  2D SolarSystemTests
//
//  Exercises the pure orbit layout math that decides where every body is drawn.
//

import Testing
import Foundation
import CoreGraphics
import simd
@testable import _D_SolarSystem

@Suite("OrbitMath")
struct OrbitMathTests {

    @Test("Larger semi-major axis maps to a larger on-screen radius")
    func radiusOrdering() {
        let inner = OrbitMath.orbitRadius(semiMajorAxis: 57.9, maxSemiMajorAxis: 4495, minRadius: 20, maxRadius: 300)
        let outer = OrbitMath.orbitRadius(semiMajorAxis: 4495, maxSemiMajorAxis: 4495, minRadius: 20, maxRadius: 300)
        #expect(inner < outer)
        #expect(outer == 300)     // the largest orbit maps exactly to maxRadius
        #expect(inner >= 20)      // nothing collapses inside minRadius
    }

    @Test("Degenerate inputs return the minimum radius, never a crash")
    func radiusDegenerate() {
        #expect(OrbitMath.orbitRadius(semiMajorAxis: 0, maxSemiMajorAxis: 0, minRadius: 12, maxRadius: 100) == 12)
        #expect(OrbitMath.orbitRadius(semiMajorAxis: -5, maxSemiMajorAxis: 100, minRadius: 12, maxRadius: 100) == 12)
    }

    @Test("Shorter-period bodies sweep a larger angle in the same elapsed time")
    func angularVelocityOrdering() {
        let t: TimeInterval = 10
        let mercury = OrbitMath.angle(elapsed: t, periodDays: 88, referencePeriodDays: 60189, secondsPerReferenceOrbit: 60, phase: 0)
        let neptune = OrbitMath.angle(elapsed: t, periodDays: 60189, referencePeriodDays: 60189, secondsPerReferenceOrbit: 60, phase: 0)
        #expect(mercury > neptune)
    }

    @Test("Angle increases monotonically with elapsed time")
    func angleMonotonic() {
        let a = OrbitMath.angle(elapsed: 1, periodDays: 365, referencePeriodDays: 365, secondsPerReferenceOrbit: 30, phase: 0.2)
        let b = OrbitMath.angle(elapsed: 2, periodDays: 365, referencePeriodDays: 365, secondsPerReferenceOrbit: 30, phase: 0.2)
        #expect(b > a)
    }

    @Test("Degenerate timing returns the starting phase")
    func angleDegenerate() {
        #expect(OrbitMath.angle(elapsed: 5, periodDays: 0, referencePeriodDays: 365, secondsPerReferenceOrbit: 30, phase: 1.23) == 1.23)
    }

    @Test("A circular orbit centres on the Sun (no focal offset)")
    func ellipseCircular() {
        let e = OrbitMath.orbitEllipse(radius: 100, eccentricity: 0, yScale: 1)
        #expect(e.focalOffset == 0)
        #expect(e.size.width == 200)
        #expect(e.size.height == 200)
    }

    @Test("An eccentric orbit offsets the centre by c = a·e and flattens the minor axis")
    func ellipseEccentric() {
        let e = OrbitMath.orbitEllipse(radius: 100, eccentricity: 0.5, yScale: 1)
        #expect(abs(e.focalOffset - 50) < 0.0001)
        let expectedHeight = CGFloat(200 * (1 - 0.25).squareRoot())   // 2·b, b = a·√(1−e²)
        #expect(abs(e.size.height - expectedHeight) < 0.0001)
    }

    @Test("Eccentricity is clamped so garbage data can't break layout")
    func ellipseClamped() {
        let e = OrbitMath.orbitEllipse(radius: 100, eccentricity: 5, yScale: 1)   // absurd e
        #expect(e.focalOffset <= 95)    // clamped to 0.95 → 95
        #expect(e.size.height > 0)      // minor axis stays real and non-zero
    }

    @Test("A body sits exactly on its own ring at periapsis and apoapsis")
    func positionMatchesRing() {
        let r: CGFloat = 120
        let ecc = 0.2
        let ellipse = OrbitMath.orbitEllipse(radius: r, eccentricity: ecc, yScale: 0.5)
        let peri = OrbitMath.position(radius: r, angle: 0, eccentricity: ecc, yScale: 0.5)
        let apo = OrbitMath.position(radius: r, angle: .pi, eccentricity: ecc, yScale: 0.5)
        #expect(abs(peri.x - (ellipse.focalOffset + r)) < 0.0001)
        #expect(abs(apo.x - (ellipse.focalOffset - r)) < 0.0001)
        #expect(abs(peri.y) < 0.0001)
    }

    @Test("Kepler solver satisfies M = E - e sin(E)")
    func keplerSolverResidual() {
        let meanAnomaly = 1.3
        let eccentricity = 0.42
        let eccentricAnomaly = OrbitMath.eccentricAnomaly(meanAnomaly: meanAnomaly, eccentricity: eccentricity)
        let residual = eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly
        #expect(abs(residual) < 0.000001)
    }

    @Test("Keplerian positions hit perihelion and aphelion distances")
    func keplerianPerihelionAphelion() {
        let semiMajorAxis = 10.0
        let eccentricity = 0.2
        let perihelion = OrbitMath.keplerianPosition(
            semiMajorAxis: semiMajorAxis,
            eccentricity: eccentricity,
            meanAnomaly: 0
        )
        let aphelion = OrbitMath.keplerianPosition(
            semiMajorAxis: semiMajorAxis,
            eccentricity: eccentricity,
            meanAnomaly: .pi
        )

        #expect(abs(simd_length(perihelion) - semiMajorAxis * (1 - eccentricity)) < 0.0001)
        #expect(abs(simd_length(aphelion) - semiMajorAxis * (1 + eccentricity)) < 0.0001)
    }

    @Test("Inclined Keplerian orbit leaves the flat orbital plane")
    func keplerianInclination() {
        let position = OrbitMath.keplerianPosition(
            semiMajorAxis: 1,
            eccentricity: 0,
            meanAnomaly: .pi / 2,
            inclinationRadians: .pi / 2
        )

        #expect(abs(position.y - 1) < 0.0001)
        #expect(abs(position.z) < 0.0001)
    }

    @Test("Compressed physical diameter preserves radius ordering")
    func compressedDiameterOrdering() {
        let mercury = OrbitMath.compressedDiameter(
            physicalRadius: 2_439.7,
            minPhysicalRadius: 2_439.7,
            maxPhysicalRadius: 69_911,
            minDiameter: 0.04,
            maxDiameter: 0.14
        )
        let earth = OrbitMath.compressedDiameter(
            physicalRadius: 6_371,
            minPhysicalRadius: 2_439.7,
            maxPhysicalRadius: 69_911,
            minDiameter: 0.04,
            maxDiameter: 0.14
        )
        let jupiter = OrbitMath.compressedDiameter(
            physicalRadius: 69_911,
            minPhysicalRadius: 2_439.7,
            maxPhysicalRadius: 69_911,
            minDiameter: 0.04,
            maxDiameter: 0.14
        )

        #expect(mercury < earth)
        #expect(earth < jupiter)
        #expect(abs(mercury - 0.04) < 0.0001)
        #expect(abs(jupiter - 0.14) < 0.0001)
    }
}
