/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Quick 3D Physics Module.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "qabstractcollisionshape_p.h"

#include <QtQml/QQmlListReference>

#include "qdynamicsworld_p.h"

QT_BEGIN_NAMESPACE

/*!
    \qmltype CollisionShape
    \inherits Node
    \inqmlmodule QtQuick3DPhysics
    \since 6.4
    \brief Base type for collision shapes.

    This is the base type for all collision shapes.
*/

/*!
    \qmlproperty bool CollisionNode::enableDebugView
    This property enables drawing the shape's debug view.
*/

QAbstractCollisionShape::QAbstractCollisionShape(QQuick3DNode *parent) : QQuick3DNode(parent)
{
    connect(this, &QQuick3DNode::sceneScaleChanged, this,
            &QAbstractCollisionShape::handleScaleChange);
}

QAbstractCollisionShape::~QAbstractCollisionShape() = default;

bool QAbstractCollisionShape::enableDebugView() const
{
    return m_enableDebugView;
}

void QAbstractCollisionShape::setEnableDebugView(bool enableDebugView)
{
    if (m_enableDebugView == enableDebugView)
        return;

    if (auto world = QDynamicsWorld::getWorld(); world != nullptr && enableDebugView)
        world->setHasIndividualDebugView();

    m_enableDebugView = enableDebugView;
    emit enableDebugViewChanged(m_enableDebugView);
}

void QAbstractCollisionShape::handleScaleChange()
{
    auto newScale = sceneScale();
    if (!qFuzzyCompare(newScale, m_prevScale)) {
        m_prevScale = newScale;
        m_scaleDirty = true;
        emit needsRebuild(this); // TODO: remove signal argument?
    }
}

QT_END_NAMESPACE
