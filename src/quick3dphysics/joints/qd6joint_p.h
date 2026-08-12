// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QD6JOINT_P_H
#define QD6JOINT_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <QtQuick3DPhysics/private/qjoint_p.h>
#include <QtQml/qqmlregistration.h>

#include <extensions/PxD6Joint.h>

QT_BEGIN_NAMESPACE

class Q_QUICK3DPHYSICS_EXPORT QD6Joint : public QPhysicsJoint
{
    Q_OBJECT
    // Motion states for 6 degrees of freedom
    Q_PROPERTY(Motion xMotion READ xMotion WRITE setXMotion NOTIFY xMotionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(Motion yMotion READ yMotion WRITE setYMotion NOTIFY yMotionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(Motion zMotion READ zMotion WRITE setZMotion NOTIFY zMotionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(Motion twistMotion READ twistMotion WRITE setTwistMotion NOTIFY twistMotionChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(Motion swingMotionY READ swingMotionY WRITE setSwingMotionY NOTIFY swingMotionYChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(Motion swingMotionZ READ swingMotionZ WRITE setSwingMotionZ NOTIFY swingMotionZChanged
                       FINAL REVISION(6, 13))

    // Linear limits per axis
    Q_PROPERTY(float linearLimitXLower READ linearLimitXLower WRITE setLinearLimitXLower NOTIFY linearLimitXLowerChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearLimitXUpper READ linearLimitXUpper WRITE setLinearLimitXUpper NOTIFY linearLimitXUpperChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearLimitYLower READ linearLimitYLower WRITE setLinearLimitYLower NOTIFY linearLimitYLowerChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearLimitYUpper READ linearLimitYUpper WRITE setLinearLimitYUpper NOTIFY linearLimitYUpperChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearLimitZLower READ linearLimitZLower WRITE setLinearLimitZLower NOTIFY linearLimitZLowerChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearLimitZUpper READ linearLimitZUpper WRITE setLinearLimitZUpper NOTIFY linearLimitZUpperChanged
                       FINAL REVISION(6, 13))

    // Angular limits
    Q_PROPERTY(float twistLimitLower READ twistLimitLower WRITE setTwistLimitLower NOTIFY twistLimitLowerChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float twistLimitUpper READ twistLimitUpper WRITE setTwistLimitUpper NOTIFY twistLimitUpperChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float swingLimitAngleY READ swingLimitAngleY WRITE setSwingLimitAngleY NOTIFY swingLimitAngleYChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float swingLimitAngleZ READ swingLimitAngleZ WRITE setSwingLimitAngleZ NOTIFY swingLimitAngleZChanged
                       FINAL REVISION(6, 13))

    // Spring parameters for soft constraints / flexible behavior
    Q_PROPERTY(float linearStiffness READ linearStiffness WRITE setLinearStiffness NOTIFY linearStiffnessChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float linearDamping READ linearDamping WRITE setLinearDamping NOTIFY linearDampingChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float angularStiffness READ angularStiffness WRITE setAngularStiffness NOTIFY angularStiffnessChanged
                       FINAL REVISION(6, 13))
    Q_PROPERTY(float angularDamping READ angularDamping WRITE setAngularDamping NOTIFY angularDampingChanged
                       FINAL REVISION(6, 13))

    QML_NAMED_ELEMENT(D6Joint)
    QML_ADDED_IN_VERSION(6, 13)

public:
    enum class Motion {
        Locked,
        Limited,
        Free
    };
    Q_ENUM(Motion)

    QD6Joint();
    ~QD6Joint() override = default;

    Motion xMotion() const;
    void setXMotion(Motion motion);

    Motion yMotion() const;
    void setYMotion(Motion motion);

    Motion zMotion() const;
    void setZMotion(Motion motion);

    Motion twistMotion() const;
    void setTwistMotion(Motion motion);

    float linearLimitXLower() const;
    void setLinearLimitXLower(float limit);

    float linearLimitXUpper() const;
    void setLinearLimitXUpper(float limit);

    float linearLimitYLower() const;
    void setLinearLimitYLower(float limit);

    float linearLimitYUpper() const;
    void setLinearLimitYUpper(float limit);

    float linearLimitZLower() const;
    void setLinearLimitZLower(float limit);

    float linearLimitZUpper() const;
    void setLinearLimitZUpper(float limit);

    float twistLimitLower() const;
    void setTwistLimitLower(float limit);

    float twistLimitUpper() const;
    void setTwistLimitUpper(float limit);

    float linearStiffness() const;
    void setLinearStiffness(float stiffness);

    float linearDamping() const;
    void setLinearDamping(float damping);

    float angularStiffness() const;
    void setAngularStiffness(float stiffness);

    float angularDamping() const;
    void setAngularDamping(float damping);

    Motion swingMotionY() const;
    void setSwingMotionY(Motion newSwingMotionY);

    Motion swingMotionZ() const;
    void setSwingMotionZ(Motion newSwingMotionZ);

    float swingLimitAngleY() const;
    void setSwingLimitAngleY(float newSwingLimitAngleY);

    float swingLimitAngleZ() const;
    void setSwingLimitAngleZ(float newSwingLimitAngleZ);

signals:
    void xMotionChanged();
    void yMotionChanged();
    void zMotionChanged();
    void twistMotionChanged();
    void linearLimitXLowerChanged();
    void linearLimitXUpperChanged();
    void linearLimitYLowerChanged();
    void linearLimitYUpperChanged();
    void linearLimitZLowerChanged();
    void linearLimitZUpperChanged();
    void twistLimitLowerChanged();
    void twistLimitUpperChanged();
    void linearStiffnessChanged();
    void linearDampingChanged();
    void angularStiffnessChanged();
    void angularDampingChanged();

    void swingMotionYChanged();
    void swingMotionZChanged();
    void swingLimitAngleYChanged();
    void swingLimitAngleZChanged();

protected:
    physx::PxJoint *createPhysxJoint(physx::PxRigidActor *actorA,
                                     physx::PxRigidActor *actorB,
                                     const physx::PxTransform &trfA,
                                     const physx::PxTransform &trfB) override;
    void setJointProperties() override;

private:
    Motion m_xMotion = Motion::Locked;
    Motion m_yMotion = Motion::Locked;
    Motion m_zMotion = Motion::Locked;
    Motion m_twistMotion = Motion::Locked;
    Motion m_swingMotionY = Motion::Locked;
    Motion m_swingMotionZ = Motion::Locked;

    // Linear limits
    float m_linearLimitXLower = -1.0f;
    float m_linearLimitXUpper = 1.0f;
    float m_linearLimitYLower = -1.0f;
    float m_linearLimitYUpper = 1.0f;
    float m_linearLimitZLower = -1.0f;
    float m_linearLimitZUpper = 1.0f;

    // Angular limits (Twist: [-45 deg, 45 deg], Swing: 45 deg in radians)
    float m_twistLimitLower = -float(M_PI_4);
    float m_twistLimitUpper = float(M_PI_4);
    float m_swingLimitAngleY = float(M_PI_4);
    float m_swingLimitAngleZ = float(M_PI_4);

    // Spring & Damping (0.0f means hard limits by default)
    float m_linearStiffness = 0.0f;
    float m_linearDamping = 0.0f;
    float m_angularStiffness = 0.0f;
    float m_angularDamping = 0.0f;

};

QT_END_NAMESPACE

#endif // QD6JOINT_P_H
